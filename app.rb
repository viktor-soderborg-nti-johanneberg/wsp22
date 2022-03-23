require 'sinatra'
require 'slim'

require_relative 'model.rb'

# https://github.com/pure-css/pure/blob/master/site/static/layouts/marketing/index.html
# https://purecss.io/layouts/marketing/

#Test account: {Username: Bob, Password: 7}

#cooldown vid inloggning

enable :sessions
logged_in = false
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
  if checkLogin(username, password)
    session[:id] = getUserId(username)
    session[:username] = username
    logged_in = true
    role = getRole(session[:id].first["id"]).first["role"]
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
  if logged_in
    id = session[:id].first["id"]
    activities = getActivities(id)
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

post('/activities') do
  name = params[:name]
  time = params[:time]
  milestones = getMilestones(session[:id].first["id"])
  updateMilestones(session[:id].first["id"], time, milestones)
  createActivity(name, session[:id].first["id"], time)
  redirect('/activities')
end

post('/activities/:id/update') do
  id = params[:id].to_i
  name = params[:name]
  time = params[:time]
  updateActivity(name, time, id)
  milestones = getMilestones(session[:id].first["id"])
  updateMilestones(session[:id].first["id"], time, milestones)
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

post('/users') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == password_confirm
    registerUser(username, password)
    session[:id] = getUserId(username)
    logged_in = true
    session[:username] = username
    p admin
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
  admin = false
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
  id = params[:id].to_i
  deleteUser(id)
  redirect('/admin')
end

post('/users/:id/edit') do
  id = params[:id].to_i
  role = params[:role]
  editUser(id, role)
  redirect('/admin')
end

get('/passerror') do
  slim(:wrong_password, locals:{logged_in:logged_in})
end

post('/user/:id/update') do
  beginDate = params[:birthday]
  endDate = Time.now
  p endDate - beginDate
end