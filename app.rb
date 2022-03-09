require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

# Todo: milestones

# https://github.com/pure-css/pure/blob/master/site/static/layouts/marketing/index.html
# https://purecss.io/layouts/marketing/

enable :sessions
logged_in = false
db = ""
admin = false

before do
  db = SQLite3::Database.new('db/slutprojekt.db')
  db.results_as_hash = true
end

get('/') do
  slim(:index, locals:{logged_in:logged_in, admin:admin})
end

get('/register') do
  slim(:register, locals:{logged_in:logged_in})
end

get('/showlogin') do
  slim(:login, locals:{logged_in:logged_in})
end

post('/login') do
  username = params[:username]
  password = params[:password]
  result = db.execute("SELECT * FROM user WHERE username = ?",username).first
  pwdigest = result["pwdigest"]
  id = result["id"]
  role = result["role"]

  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    session[:username] = username
    logged_in = true
    if role == "admin"
      admin = true
    end
    redirect('/activities')
  else
    logged_in = false
    "FEL LÖSENORD!"
  end
end

get('/activities') do
  id = session[:id].to_i
  activities = db.execute('SELECT * FROM activities WHERE user_id = ?',id)
  if logged_in
    slim(:"activities/index", locals:{activities:activities, logged_in:logged_in, admin:admin})
  else
    slim(:error, locals:{activities:activities, logged_in:logged_in})
  end
end

post('/activities/:id/delete') do
  id = params[:id].to_i
  db.execute('DELETE FROM activities WHERE id = ?',id)
  redirect('/activities')
end

post('/activities/new') do
  name = params[:name]
  hrs = params[:hrs]
  if db.execute('SELECT * FROM activities WHERE user_id = ?', session[:id]).length == 0
    db.execute('INSERT INTO usermilerel (user_id, milestone_id) VALUES (?,?)', session[:id], 1)
  end
  db.execute("INSERT INTO activities (name, user_id, time) VALUES (?,?,?)",name, session[:id], hrs)
  redirect('/activities')
end

post('/activities/:id/update') do
  id = params[:id].to_i
  name = params[:name]
  time = params[:time]
  db.execute("UPDATE activities SET name=?,time=? WHERE id =?",name,time,id)
  redirect('/activities')
end

get('/activities/:id/edit') do
  id = params[:id].to_i
  result = db.execute("SELECT * FROM activities WHERE id = ?",id).first 
  slim(:"/activities/edit", locals:{result:result, logged_in:logged_in, admin:admin})
end

post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == password_confirm
    password_digest = BCrypt::Password.create(password)
    db.execute('INSERT INTO user (username,pwdigest,role) VALUES (?,?,?)',username,password_digest,"member")
    session[:id] = db.execute('SELECT id FROM user WHERE username = ?', username).first["id"]
    logged_in = true
    session[:username] = username
    redirect('/')
  else
    "Lösenorden matchade inte"
  end
end

get('/user/:id') do
  id = params[:id].to_i
  user = db.execute('SELECT * FROM user WHERE id = ?', id).first
  milestones = db.execute('SELECT * FROM usermilerel INNER JOIN milestones ON usermilerel.milestone_id = milestones.id WHERE user_id = ?',id)
  allmile = db.execute('SELECT * FROM milestones')
  if logged_in
    slim(:"users/user", locals:{logged_in:logged_in, username:user["username"], milestones:milestones, allmile:allmile, admin:admin, user:user})
  else
    slim(:error, locals:{logged_in:logged_in, username:user["username"], milestones:milestones, allmile:allmile})
  end
end

post('/logout') do
  logged_in = false
  session.destroy
  redirect('/')
end

get('/admin') do
  if logged_in && admin
    users = db.execute('SELECT * FROM user')
    slim(:admin, locals:{logged_in:logged_in, admin:admin, users:users})
  else
    slim(:error, locals:{logged_in:logged_in})
  end
end

get('/members') do
  if logged_in
    users = db.execute('SELECT * FROM user')
    slim(:"users/members", locals:{logged_in:logged_in, admin:admin, users:users})
  else
    slim(:error, locals:{logged_in:logged_in})
  end
end

post('/users/:id/delete') do
  id = params[:id].to_i
  db.execute('DELETE FROM user WHERE id = ?', id)
  redirect('/admin')
end

post('/users/:id/edit') do
  id = params[:id].to_i
  role = params[:role]
  db.execute('UPDATE user SET role = ? WHERE id = ?', role, id)
  if role == "admin"
    admin = true
  else
    admin = false
  end
  redirect('/admin')
end