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
    
    #def is_safe(self, cell):
        #return (not self.pit_possible(cell) 
                #and not self.wumpus_possible(cell))


class Cell:
    def __init__(self, v = False, s = False):
        self.visited = v
        self.safe = s
        self.breeze = False
        self.stench = False
        self.w_poss = False
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

class Advisor:
    def __init__(self):
        self.pos = (0, 0)
        self.dir = 0
        self.arrows = 0
        self.shots = []

        self.cells = dict()
        self.cells[self.pos] = Cell(v=True, s=True)

        self.kb = WumpusKB()
        no_pit = -self.kb.pit(0,0)
        no_wumpus = -self.kb.wumpus(0,0)
        self.kb.add_clause([no_pit])
        self.kb.add_clause([no_wumpus])

        adj = self.adj(self.pos)
        for c in adj:
            self.cells[c] = Cell(s=True)

        self.kb.no_pits(adj)
        self.kb.no_wumpuses(adj)

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
    
    def is_safe(self, c):
        cell = self.cells[c]
        if cell.safe:
            return True
        # if not safe, checks knowledge base
        cell.w_poss = self.kb.wumpus_possible(c)
        if not cell.w_poss and not self.kb.pit_possible(c):
            cell.safe = True
            return True
        
        return False


    def adj(self, pos):
        x,y = pos
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
        stench, breeze, glitter, bump = sensors

        if bump == '1': # wall
            wall = self.forward_pos()
            self.cells[wall].wall = True
            self.cells[wall].visited = True
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
        for c in self.adj(self.pos):
            if c not in self.cells:
                self.cells[c] = Cell()

        adj = [c for c in self.adj(self.pos) if not self.cells[c].wall]

        if breeze == '1':
            self.cells[self.pos].breeze = True
            self.kb.pits(adj)
        else:
            self.kb.no_pits(adj)

        if stench == '1':
            self.cells[self.pos].stench = True
            self.kb.wumpuses(adj)
        else:
            self.kb.no_wumpuses(adj)
        
        # checking safety
        for c in adj:
            self.is_safe(c)
    

    def get_offset(self, target):
        x,y = self.pos
        tx,ty = target
        return (tx - x, ty - y)
    
    def is_valid_move(self, cell):
        safe = self.is_safe(cell)
        visited = self.cells[cell].visited
        wall = self.cells[cell].wall
        return safe and not visited and not wall
    
    def is_valid_shot(self, cell):
        visited = self.cells[cell].visited
        wall = self.cells[cell].wall
        return not visited and not wall
    
    def choose(self):
        # looks for closest unvisited safe cell 
        target = self.best_move()
        if target:
            return self.get_offset(target)
        
        #otherwise, looks for wumpus to shoot
        if self.arrows > 0:
            target = self.best_shot()
            if target:
                return "s, " + str(self.get_offset(target))

        # gives up
        return "e"
    
    def move_cost(self, cell):
        dx,dy = self.get_offset(cell)
        dist = abs(dx) + abs(dy)

        if abs(dx) > abs(dy):
            dir = 1 if dx > 0 else 3 # E else W
        else:
            dir = 0 if dy > 0 else 2 # N else S
        
        turns = min((dir - self.dir) % 4, (self.dir - dir) % 4)

        return (dist, turns)
    
    def best_move(self):
        best = None
        best_cost = (float("inf"), float("inf")) 

        for c in self.cells:
            if self.is_valid_move(c):
                
                cost = self.move_cost(c)

                if cost < best_cost:
                    best = c
                    best_cost = cost
        
        return best

    def adj_stats(self, cell):
        unknown = 0
        stenches = 0
        breezes = 0
        walls = 0
    
        for a in self.adj(cell):
            if a not in self.cells or not self.cells[a].visited:
                unknown += 1
            else:
                if self.cells[a].stench:
                    stenches += 1
                if self.cells[a].breeze:
                    breezes += 1
                if self.cells[a].wall:
                    walls += 1

        return (unknown, stenches, breezes, walls)
    
    def best_shot(self):
        best = None
        best_u = 0
        best_b = 4
        best_w = 4
        best_cost = (float("inf"), float("inf")) 

        for c in self.cells:
            if self.is_valid_shot(c):
                # getting the amount of unkown cells, stenches, breezes and 
                # walls adjacent to c
                u, s, b, w = self.adj_stats(c)
                cost = self.move_cost(c)

                if b >= s:
                    continue # more chance of a pit than a wumpus
                if u < best_u:
                    continue
                if u == best_u:
                    if b > best_b or w > best_w:
                        continue
                    if cost >= best_cost:
                        continue

                best = c
                best_u = u
                best_b = b
                best_w = w
                best_cost = cost

        #print(best_u, file=sys.stderr)
        return best
    
    def is_forward_safe(self):
        fp = self.forward_pos()

        # checking in case fp turned safe after a shot
        self.check_shots()

        if self.is_safe(fp):
            return True
        
        return False
    
    def check_shots(self):
        # loops thru a copy to avoid skipping elements after remove
        for shot in self.shots[:]:
            pos, dir, scream = shot
            cells = []

            if dir == 0: # N
                cells = [c for c in self.cells if c[0] == pos[0] and c[1] > pos[1]]
            elif dir == 1: # E
                cells = [c for c in self.cells if c[1] == pos[1] and c[0] > pos[0]]
            elif dir == 2: # S
                cells = [c for c in self.cells if c[0] == pos[0] and c[1] < pos[1]]
            else: # W
                cells = [c for c in self.cells if c[1] == pos[1] and c[0] < pos[0]]

            if scream:
                for c in cells:
                    cell = self.cells[c]
                    if cell.w_poss:
                        no_wumpus = -self.kb.wumpus(c[0],c[1])
                        self.kb.add_clause([no_wumpus])
                        self.shots.remove(shot)
                        break
            else:
                for c in cells:
                    cell = self.cells[c]
                    #cell.w_poss = False
                    no_wumpus = -self.kb.wumpus(c[0],c[1])
                    self.kb.add_clause([no_wumpus])
                    if cell.wall:
                        self.shots.remove(shot)
                        break       

    def arrow_shot(self, scream):
        shot = (self.pos, self.dir, scream)
        self.shots.append(shot)
        
        self.arrows -= 1
        


advisor = Advisor()

while True:
    line = sys.stdin.readline()
    if not line:
        break

    input = line.strip().split()
    if not len(input) > 0:
        break

    if input[0] == "h": # player asked help
        move = advisor.choose()
        print(move, flush=True)
    elif input[0] == "c": # check safety
        safe = advisor.is_forward_safe()
        print(safe, flush=True)
    elif input[0] == "l": # player turned left
        advisor.turn_left()
    elif input[0] == "r": # player turned right
        advisor.turn_right()
    elif input[0] == "a": # player got arrows
        advisor.add_arrows(int(input[1]))
    elif input[0] == "s": # player shot arrow
        advisor.arrow_shot(int(input[1]))
    elif len(input[0]) == 4: # player moved, input == sensors
        advisor.update(input[0])
    else:
        break