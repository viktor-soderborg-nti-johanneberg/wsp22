require 'sinatra'
require 'slim'

require_relative 'model.rb'

# https://github.com/pure-css/pure/blob/master/site/static/layouts/marketing/index.html
# https://purecss.io/layouts/marketing/

#Test account: {Username: Bob, Password: 7}

enable :sessions
logged_in = false
db = ""
admin = false

get('/') do
  slim(:index, locals:{logged_in:logged_in, admin:admin})
end

get('/register') do
  if logged_in
    slim(:logout_error, locals:{logged_in:logged_in, admin:admin})
  else
    slim(:register, locals:{logged_in:logged_in, admin:admin})
  end
end

get('/showlogin') do
  if logged_in
    slim(:logout_error, locals:{logged_in:logged_in, admin:admin})
  else
    slim(:login, locals:{logged_in:logged_in, admin:admin})
  end
end

post('/login') do
  username = params[:username]
  password = params[:password]
  if checkLogin(username)
    session[:id] = id
    session[:username] = username
    logged_in = true
    if role == "admin"
      admin = true
    end
    redirect('/activities')
  else
    logged_in = false
    redirect('/passerror')
  end
end

get('/activities') do
  id = session[:id].to_i
  activities = getActivities(id)
  if logged_in
    slim(:"activities/index", locals:{activities:activities, logged_in:logged_in, admin:admin})
  else
    slim(:login_error, locals:{activities:activities, logged_in:logged_in})
  end
end

post('/activities/:id/delete') do
  id = params[:id].to_i
  deleteActivity(id)
  redirect('/activities')
end

post('/activities/new') do
  name = params[:name]
  time = params[:time]
  milestones = getMilestones(session[:id])
  updateMilestones(session[:id], time, milestones)
  createActivity(name, session[:id], time)
  redirect('/activities')
end

post('/activities/:id/update') do
  id = params[:id].to_i
  name = params[:name]
  time = params[:time]
  milestones = getMilestones(session[:id])
  updateMilestones(session[:id], time, milestones)
  redirect('/activities')
end

get('/activities/:id/edit') do
  id = params[:id].to_i
  result = editActivity(id)
  if logged_in
    slim(:"/activities/edit", locals:{result:result, logged_in:logged_in, admin:admin})
  else
    slim(:login_error, locals:{result:result, logged_in:logged_in, admin:admin, username:session["username"]})
  end
end

post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == password_confirm
    session[:id] = registerUser(username, password)
    logged_in = true
    session[:username] = username
    redirect('/')
  else
    "Lösenorden matchade inte"
  end
end

get('/user/:id') do
  id = params[:id].to_i
  user = getUser(id)
  milestones = showMilestones(id)
  allmile = allMilestones()
  if logged_in
    slim(:"users/user", locals:{logged_in:logged_in, username:user["username"], milestones:milestones, allmile:allmile, admin:admin, user:user})
  else
    slim(:login_error, locals:{logged_in:logged_in, username:user["username"], milestones:milestones, allmile:allmile})
  end
end

post('/logout') do
  logged_in = false
  session.destroy
  redirect('/')
end

get('/admin') do
  if logged_in && admin
    users = getUsers()
    slim(:admin, locals:{logged_in:logged_in, admin:admin, users:users})
  else
    slim(:login_error, locals:{logged_in:logged_in})
  end
end

get('/members') do
  if logged_in
    users = getUsers()
    slim(:"users/members", locals:{logged_in:logged_in, admin:admin, users:users})
  else
    slim(:login_error, locals:{logged_in:logged_in})
  end
end

post('/users/:id/delete') do
  deleteUser(id)
  id = params[:id].to_i
  redirect('/admin')
end

post('/users/:id/edit') do
  id = params[:id].to_i
  role = params[:role]
  editUser(id, role)
  if role == "admin"
    admin = true
  else
    admin = false
  end
  redirect('/admin')
end

get('/passerror') do
  slim(:wrong_password, locals:{logged_in:logged_in})
end