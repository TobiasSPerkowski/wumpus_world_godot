import sys
from pysat.solvers import Solver
from pysat.formula import IDPool


class WumpusKB:
    def __init__(self):
        self.vpool = IDPool()
        self.solver = Solver(name='glucose3')

    def pit(self, x,y):
        return self.vpool.id(f"P_{x}_{y}")

    def wumpus(self, x,y):
        return self.vpool.id(f"W_{x}_{y}")

    def add_clause(self, c):
        self.solver.add_clause(c)

    def no_pits(self, adj):
        for x,y in adj:
            self.add_clause([-self.pit(x,y)])

    def pits(self, adj):
        clause = [self.pit(x,y) for x,y in adj]
        if clause:
            self.add_clause(clause)

    def no_wumpuses(self, adj):
        for x,y in adj:
            self.add_clause([-self.wumpus(x,y)])

    def wumpuses(self, adj):
        clause = [self.wumpus(x,y) for x,y in adj]
        if clause:
            self.add_clause(clause)

    def pit_possible(self, cell):
        p = self.pit(cell[0], cell[1])
        return self.solver.solve(assumptions=[p])

    def wumpus_possible(self, cell):
        w = self.wumpus(cell[0], cell[1])
        return self.solver.solve(assumptions=[w])

    def is_safe(self, cell):
        return (not self.pit_possible(cell) 
                and not self.wumpus_possible(cell))


class Cell:
    def __init__(self, v = False, s = False):
        self.visited = v
        self.safe = s
        self.breeze = False
        self.stench = False
        self.wall = False
    
    def __str__(self):
        v = "visited" if self.visited else "not visited"
        sa = "safe" if self.safe else "not safe"
        b = "breeze" if self.breeze else "no breeze"
        st = "stench" if self.stench else "no stench"
        w = "wall" if self.wall else "no wall"
        return v + ", " + sa + ", " + b + ", " + st + ", " + w


MOVES = [
    ( 0, 1),  # N
    ( 1, 0),  # E
    ( 0,-1),  # S
    (-1, 0)   # W
]

class Agent:
    def __init__(self):
        self.pos = (0, 0)
        self.dir = 0
        self.arrows = 1

        self.cells = dict()
        self.cells[self.pos] = Cell(v=True)
        for c in self.adj():
            self.cells[c] = Cell(s=True)

        self.kb = WumpusKB()

    def add_arrows(self, amount):
        self.arrows += amount

    def turn_left(self):
        self.dir = (self.dir - 1) % 4 
    
    def turn_right(self):
        self.dir = (self.dir + 1) % 4 

    def forward_pos(self):
        x,y = self.pos
        dx,dy = MOVES[self.dir]
        return (x + dx, y + dy)

    def adj(self):
        x,y = self.pos
        # retornando na melhor ordem (evita giros desnecessarios)
        if self.dir == 0: #N
            return [(x, y+1), (x-1, y), (x, y-1), (x+1, y)]
        if self.dir == 1: #E
            return [(x+1, y), (x, y+1), (x-1, y), (x, y-1)]
        if self.dir == 2: #S
            return [(x, y-1), (x+1, y), (x, y+1), (x-1, y)]
        #W
        return [(x-1, y), (x, y-1), (x+1, y), (x, y+1)]

    def update(self, sensors):
        stench, breeze, glitter, bump, scream = sensors

        if bump == '1': # wall
            wall = self.forward_pos()
            self.cells[wall].wall = True
            # updating kb 
            no_pit = -self.kb.pit(wall[0], wall[1])
            no_wumpus = -self.kb.wumpus(wall[0], wall[1])
            self.kb.add_clause([no_pit])
            self.kb.add_clause([no_wumpus])
            return

        # updating vars and kb
        self.pos = self.forward_pos()
        curr_cell = self.cells[self.pos]
        curr_cell.visited = True
        curr_cell.safe = True
        for c in self.adj():
            if c not in self.cells:
                self.cells[c] = Cell()

        adj = [c for c in self.adj() if not self.cells[c].wall]

        if breeze == '1':
            curr_cell.breeze = True
            self.kb.pits(adj)
        else:
            self.kb.no_pits(adj)

        if stench == '1':
            curr_cell.stench = True
            self.kb.wumpuses(adj)
        else:
            self.kb.no_wumpuses(adj)
        
        # checking safety
        for c in adj:
            cell = self.cells[c]
            if not cell.visited and not cell.safe:
                if self.kb.is_safe(c):
                    cell.safe = True
    

    def get_move(self, target):
        x,y = self.pos
        tx,ty = target
        return (tx - x, ty - y)
    
    def is_valid_target(self, cell):
        safe = self.cells[cell].safe
        visited = self.cells[cell].visited
        wall = self.cells[cell].wall
        return safe and not visited and not wall
    
    def choose(self):
        # looks for unvisited safe cell 
        # adjacent
        for c in self.adj():
            if self.is_valid_target(c):
                return self.get_move(c)

        #frontier
        for c in self.cells:
            if self.is_valid_target(c):
                return self.get_move(c)
        
        #otherwise, tries shooting
        if self.arrows > 0:
            for c in self.cells:
                # find a way to suggest shot direction
                if self.cells[c].stench:
                    return "s, " + str(self.get_move(c))

        # gives up
        return "e"

    def arrow_shot(self):
        # store shot info
        self.arrows -= 1

    def debug(self):
        print("pos: ", self.pos)
        for c in self.cells:
            print(str(c), ": ", str(self.cells[c]))
        print("------------")
        


agent = Agent()

while True:
    line = sys.stdin.readline()
    if not line:
        break

    input = line.strip().split()

    if input[0] == "h": # player asked help
        move = agent.choose()
        print(move, flush=True)
    elif input[0] == "l": # player turned left
        agent.turn_left()
    elif input[0] == "r": # player turned right
        agent.turn_right()
    elif input[0] == "a": # player got arrows
        agent.add_arrows(input[1])
    elif input[0] == "s": # player shot arrow
        agent.arrow_shot()
    elif len(input[0]) == 5: # player moved, input == sensors
        agent.update(input[0])
    elif input[0] == "d":
        agent.debug()
    else:
        break