require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

#1. Skapa ER + databas som kan hålla användare och todos. Fota ER-diagram, 
#   lägg i misc-mapp
#2. Skapa ett formulär för att registrerara användare.
#3. Skapa ett formulär för att logga in. Om användaren lyckas logga  
#   in: Spara information i session som håller koll på att användaren är inloggad
#4. Låt inloggad användare skapa todos i ett formulär (på en ny sida ELLER på sidan som visar todos.).
#5. Låt inloggad användare updatera och ta bort sina formulär.
#6. Lägg till felhantering (meddelande om man skriver in fel user/lösen)

enable :sessions
logged_in = false
db = ""

before do
  db = SQLite3::Database.new('db/slutprojekt.db')
  db.results_as_hash = true
end

get('/') do
  slim(:index, locals:{logged_in:logged_in})  
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

  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    session[:username] = username
    logged_in = true
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
    slim(:"activities/index", locals:{activities:activities, logged_in:logged_in})
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
  db.execute("INSERT INTO activities (name, user_id, time) VALUES (?,?,?)",name, session[:id], hrs)
  redirect('/activities')
end

post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == password_confirm
    password_digest = BCrypt::Password.create(password)
    db.execute('INSERT INTO user (username,pwdigest) VALUES (?,?)',username,password_digest)
    logged_in = true
    redirect('/activities')
  else
    "Lösenorden matchade inte"
  end
end

get('/user') do
  milestones = db.execute('SELECT * FROM usermilerel INNER JOIN milestones ON usermilerel.milestone_id = milestones.id WHERE user_id = ?',session[:id])
  allmile = db.execute('SELECT * FROM milestones')
  if logged_in
    slim(:"users/user", locals:{logged_in:logged_in, username:session[:username], milestones:milestones, allmile:allmile})
  else
    slim(:error, locals:{logged_in:logged_in, username:session[:username], milestones:milestones, allmile:allmile})
  end
end

post('/logout') do
  logged_in = false
  session.destroy
  redirect('/')
end