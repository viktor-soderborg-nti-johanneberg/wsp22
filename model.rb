require 'sqlite3'
require 'bcrypt'

def checkLogin(username, password)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM user WHERE username = ?", username).first
    pwdigest = result["pwdigest"]
  
    if BCrypt::Password.new(pwdigest) == password
        return true
    else
        return false
    end
end

def createActivity(name, id, time)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute("INSERT INTO activities (name, user_id, time) VALUES (?,?,?)", name, id, time)
end

def getActivities(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    return db.execute('SELECT * FROM activities WHERE user_id = ?', id)
end

def deleteActivity(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('DELETE FROM activities WHERE id = ?', id)
    return nil
end

def updateActivity(name, time, id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute("UPDATE activities SET name=?,time=? WHERE id =?", name, time, id)
end

def editActivity(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    return db.execute("SELECT * FROM activities WHERE id = ?",id).first 
end

def getMilestones(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    return db.execute('SELECT * FROM usermilerel WHERE user_id = ?', id)
end

def updateMilestones(id, time, milestones)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    if db.execute('SELECT * FROM activities WHERE user_id = ?', id).length == 0
        db.execute('INSERT INTO usermilerel (user_id, milestone_id) VALUES (?,?)', id, 1)
    end
    if milestones.length < 2 && time.to_i >= 100
        db.execute('INSERT INTO usermilerel (user_id, milestone_id) VALUES (?,?)', id, 2)
    end
    if milestones.length < 3 && time.to_i >= 200
        db.execute('INSERT INTO usermilerel (user_id, milestone_id) VALUES (?,?)', id, 3)
    end
    if milestones.length < 4 && time.to_i >= 300
        db.execute('INSERT INTO usermilerel (user_id, milestone_id) VALUES (?,?)', id, 4)
    end
    if milestones.length < 5 && time.to_i >= 400
        db.execute('INSERT INTO usermilerel (user_id, milestone_id) VALUES (?,?)', id, 5)
    end
    if milestones.length < 6 && time.to_i >= 500
        db.execute('INSERT INTO usermilerel (user_id, milestone_id) VALUES (?,?)', id, 6)
    end
end

def registerUser(username, password)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    password_digest = BCrypt::Password.create(password)
    db.execute('INSERT INTO user (username,pwdigest,role) VALUES (?,?,?)',username,password_digest,"member")
    return nil
end

def getUser(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    return db.execute('SELECT * FROM user WHERE id = ?', id).first
end

def showMilestones(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    return db.execute('SELECT * FROM usermilerel INNER JOIN milestones ON usermilerel.milestone_id = milestones.id WHERE user_id = ?',id)
end

def allMilestones()
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    return db.execute('SELECT * FROM milestones')
end

def getUsers()
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    return db.execute('SELECT * FROM user')
end

def deleteUser(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('DELETE FROM user WHERE id = ?', id)
    db.execute('DELETE FROM usermilerel WHERE user_id = ?', id)
    db.execute('DELETE FROM activities WHERE user_id = ?', id)
    return nil
end

def editUser(id, role)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('UPDATE user SET role = ? WHERE id = ?', role, id)
    return nil
end

def getUserId(username)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('SELECT id FROM user WHERE username = ?', username)
end

def getRole(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('SELECT role FROM user WHERE id = ?', id)
end