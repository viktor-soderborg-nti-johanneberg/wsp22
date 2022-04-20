require 'sqlite3'
require 'bcrypt'

module Model
  # Finds a user
  #
  # @param [String] username The username
  # @param [String] password The password
  #
  # @return [false] if credentials do not match a user
  # @return [true] if credentials matches a user
  def checkLogin(username, password)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    result = db.execute('SELECT * FROM user WHERE username = ?', username).first
    if !result.nil?
      pwdigest = result['pwdigest']

      BCrypt::Password.new(pwdigest) == password
    else
      false
    end
  end

  # Attempts to insert a new row into the activities table
  #
  # @param [String] name The name of the activity
  # @param [Integer] id The user_id of the user
  # @param [Integer] time The time spent on activity
  #
  def createActivity(name, id, time)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('INSERT INTO activities (name, user_id, time) VALUES (?,?,?)', name, id, time)
  end

  # Finds all activities
  #
  # @param [Integer] id The user_id of the user
  #
  # @return [Hash]
  #   * :id [Integer] The ID of the activity
  #   * :name [Integer] The name of the activity
  #   * :user_id [Integer] The user_id of the user
  #   * :time [Integer] The time spent on activity
  #
  def getActivities(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('SELECT * FROM activities WHERE user_id = ?', id)
  end

  # Attempts to delete a row from the activities table
  #
  # @param [Integer] id The id of the activity
  #
  # @return nil
  def deleteActivity(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('DELETE FROM activities WHERE id = ?', id)
    nil
  end

  # Attempts to update a row in the activities table
  #
  # @param [String] name The name of the activity
  # @param [Integer] time The time spent on activity
  # @param [Integer] id The id of the activity
  def updateActivity(name, time, id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('UPDATE activities SET name=?,time=? WHERE id =?', name, time, id)
  end

  # Finds an activity
  #
  # @param [Integer] id The id of the activity
  #
  # @return [Hash]
  #   * :id [Integer] The ID of the activity
  #   * :name [Integer] The name of the activity
  #   * :user_id [Integer] The user_id of the user
  #   * :time [Integer] The time spent on activity
  #
  def editActivity(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('SELECT * FROM activities WHERE id = ?', id).first
  end

  # Finds user's milestones
  #
  # @param [Integer] id The user_id of the user
  #
  # @return [Hash]
  #   * :user_id [Integer] The ID of the user
  #   * :milestone_id [Integer] The ID of the milestone
  #
  def getMilestones(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('SELECT * FROM usermilerel WHERE user_id = ?', id)
  end

  # Attempts to update a row in the usermilerel table
  #
  # @param [Integer] id The user_id of the user
  # @param [Integer] time The time spent on activity
  # @param [Hash] milestones The milestones user already has unlocked
  # @option params [Integer] user_id The user_id of the user
  # @option params [Integer] milestone_id The id of the milestone
  #
  def updateMilestones(id, time, milestones)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    if db.execute('SELECT * FROM activities WHERE user_id = ?', id).length == 0 && milestones.length < 1
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

  # Attempts to create a new user
  #
  # @param [String] username The username
  # @param [String] password The password
  #
  # @return nil
  def registerUser(username, password)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    password_digest = BCrypt::Password.create(password)
    db.execute('INSERT INTO user (username,pwdigest,role) VALUES (?,?,?)', username, password_digest, 'member')
    nil
  end

  # Finds a user
  #
  # @param [Integer] id The id of the user
  #
  # @return [Hash]
  #   * :id [Integer] the id of the user
  #   * :username [String] the username of the user
  #   * :pwdigest [String] the crypted password of the user
  #   * :role [String] the role of the user
  #   * :birthday [Float] the miliseconds since 1st of January 1970 to user's birthday
  #
  def getUser(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('SELECT * FROM user WHERE id = ?', id).first
  end

  # Finds user's unlocked milestones
  #
  # @param [Integer] id The user_id of the user
  def showMilestones(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute(
      'SELECT * FROM usermilerel INNER JOIN milestones ON usermilerel.milestone_id = milestones.id WHERE user_id = ?', id
    )
  end

  # Finds all milstones
  #
  # @return [Hash]
  #   * :id [Integer] the id of the milestone
  #   * :name [String] the name of the milestone
  #   * :descrption [String] the description of the milestone
  def allMilestones
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('SELECT * FROM milestones')
  end

  # Finds all users
  #
  # @return [Hash]
  #   * :id [Integer] the id of the user
  #   * :username [String] the username of the user
  #   * :pwdigest [String] the crypted password of the user
  #   * :role [String] the role of the user
  #   * :birthday [Float] the miliseconds since 1st of January 1970 to user's birthday
  #
  def getUsers
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('SELECT * FROM user')
  end

  # Attempts to delete a row from the users table
  #
  # @param [Integer] id The id of the user
  #
  # @return nil
  def deleteUser(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('DELETE FROM user WHERE id = ?', id)
    db.execute('DELETE FROM usermilerel WHERE user_id = ?', id)
    db.execute('DELETE FROM activities WHERE user_id = ?', id)
    nil
  end

  # Attempts to update a row in the users table
  #
  # param [Integer] id The id of the user
  # param [String] role The role of the user
  #
  # return nil
  def editUser(id, role)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('UPDATE user SET role = ? WHERE id = ?', role, id)
    nil
  end

  # Finds an ID of a user
  #
  # @param [String] username The username of the user
  def getUserId(username)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('SELECT id FROM user WHERE username = ?', username)
  end

  # Finds a role of a user
  #
  # @param [Integer] id The id of the user
  def getRole(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('SELECT role FROM user WHERE id = ?', id)
  end

  # Attempts to update a row in users table
  #
  # param [Float] date Seconds since 1st of January 1970 to user's birthday
  # param [Integer] id The user_id of the user
  def updateBirthday(date, id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('UPDATE user SET birthday = ? WHERE id = ?', date, id)
  end

  # Finds a date of a user
  #
  # @param [Integer] id The user_id of the user
  def getDate(id)
    db = SQLite3::Database.new('db/slutprojekt.db')
    db.results_as_hash = true
    db.execute('SELECT birthday FROM user WHERE id = ?', id)
  end
end
