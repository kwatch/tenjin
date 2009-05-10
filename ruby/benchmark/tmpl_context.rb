@title = 'Epyc Benchmark Test'
@action = 'list'

class User
    def initialize(id, name, email, age, gender)
        @id = id
        @name = name
        @email = email
        @age = age
        @gender = gender
    end
    attr_accessor :id, :name, :email, :age, :gender
end

@users = [
    User.new( 1, 'Robert',    'bob@example.com',    23, 'm'),
    User.new( 2, 'Marie',     'mary@example.com',   21, 'f'),
    User.new( 3, 'William',   'bill@example.com',   24, 'm'),
    User.new( 4, 'Stephen',   'steve@example.com',  21, 'm'),
    User.new( 5, 'Katharine', 'kathy@example.com',  25, 'f'),
    User.new( 6, 'Margaret',  'meg@example.com',    29, 'f'),
    User.new( 7, 'Michael',   'mike@example.com',   22, 'm'),
    User.new( 8, 'Joseph',    'joe@example.com',    26, 'm'),
    User.new( 9, 'Edward',    'ted@example.com',    25, 'm'),
    User.new(10, 'Paul',      'paul@example.com',   23, 'm'),
    User.new(11, 'Tomas',     'tom@example.com',    25, 'm'),
    User.new(12, 'Elizabeth', 'liza@example.com',   28, 'f'),
    User.new(13, 'Benjamin',  'benn@example.com',   29, 'm'),
    User.new(14, 'Jerrald',   'jerry@example.com',  27, 'm'),
    User.new(15, 'Jonathan',  'john@example.com',   29, 'f'),
    User.new(16, 'Patrick',   'pat@example.com',    23, 'm'),
    User.new(17, 'David',     'dave@example.com',   22, 'm'),
    User.new(18, 'Daniel',    'danny@example.com',  23, 'm'),
    User.new(19, 'Martin',    'marty@example.com',  28, 'm'),
    User.new(20, 'Ann',       'ann@example.com',    24, 'f'),
#   User.new(21, 'Lucy',      'lucy@example.com',   21, 'f'),
#   User.new(22, 'Frederic',  'fred@example.com',   29, 'm'),
]
