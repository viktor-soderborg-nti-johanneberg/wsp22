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
logged_in = true

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
  db = SQLite3::Database.new('db/todo.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE username = ?",username).first
  pwdigest = result["pwdigest"]
  id = result["id"]

  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    session[:username] = username
    logged_in = true
    redirect('/todos')
  else
    logged_in = false
    "FEL LÖSENORD!"
  end
end

get('/activities') do
  id = session[:id].to_i
  db = SQLite3::Database.new('db/todo.db')
  db.results_as_hash = true
  result = db.execute('SELECT * FROM todos WHERE user_id = ?',id)
  p "Alla aktiviteter från result #{result}"
  slim(:"activities/index", locals:{activities:result, logged_in:logged_in})
end

post('/activities/:id/delete') do
  id = params[:id].to_i
  db = SQLite3::Database.new('db/todo.db')
  db.execute('DELETE FROM todos WHERE id = ?',id)
  redirect('/todos')
end

post('/activities/new') do
  db = SQLite3::Database.new("db/todo.db")  
  content = params[:content]
  db.execute("INSERT INTO todos (content, user_id) VALUES (?,?)",content, session[:id])
  redirect('/todos')
end

post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == password_confirm
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/todo.db')
    db.execute('INSERT INTO users (username,pwdigest) VALUES (?,?)',username,password_digest)
    redirect('/')
  else
    "Lösenorden matchade inte"
  end
end

get('/user') do
  slim(:user, locals:{logged_in:logged_in, username:session[:username]})
end

post('/logout') do
  logged_in = false
  session.destroy
  redirect('/')
end