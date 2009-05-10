title = 'Epyc Benchmark Test'
action = 'list'

class User:
    def __init__(self, id=None, name=None, email=None, age=None, gender=None):
        self.id = id
        self.name = name
        self.email = email
        self.age = age
        self.gender = gender

users = [
    User( 1, 'Robert',    'bob@example.com',    23, 'm'),
    User( 2, 'Marie',     'mary@example.com',   21, 'f'),
    User( 3, 'William',   'bill@example.com',   24, 'm'),
    User( 4, 'Stephen',   'steve@example.com',  21, 'm'),
    User( 5, 'Katharine', 'kathy@example.com',  25, 'f'),
    User( 6, 'Margaret',  'meg@example.com',    29, 'f'),
    User( 7, 'Michael',   'mike@example.com',   22, 'm'),
    User( 8, 'Joseph',    'joe@example.com',    26, 'm'),
    User( 9, 'Edward',    'ted@example.com',    25, 'm'),
    User(10, 'Paul',      'paul@example.com',   23, 'm'),
    User(11, 'Tomas',     'tom@example.com',    25, 'm'),
    User(12, 'Elizabeth', 'liza@example.com',   28, 'f'),
    User(13, 'Benjamin',  'benn@example.com',   29, 'm'),
    User(14, 'Jerrald',   'jerry@example.com',  27, 'm'),
    User(15, 'Jonathan',  'john@example.com',   29, 'f'),
    User(16, 'Patrick',   'pat@example.com',    23, 'm'),
    User(17, 'David',     'dave@example.com',   22, 'm'),
    User(18, 'Daniel',    'danny@example.com',  23, 'm'),
    User(19, 'Martin',    'marty@example.com',  28, 'm'),
    User(20, 'Ann',       'ann@example.com',    24, 'f'),
#   User(21, 'Lucy',      'lucy@example.com',   21, 'f'),
#   User(22, 'Frederic',  'fred@example.com',   29, 'm'),
]
