require 'sinatra'
require 'slim'

require_relative './model/model.rb'
include Model

# https://github.com/pure-css/pure/blob/master/site/static/layouts/marketing/index.html
# https://purecss.io/layouts/marketing/

# Test account: {Username: Bob, Password: 7}

# cooldown vid inloggning

enable :sessions
logged_in = false
admin = false
login_attempts = 0

# Display landing page
#
get('/') do
  slim(:index, locals:{logged_in:logged_in, admin:admin})
end

# Displays a register form
#
get('/register') do
  if logged_in
    slim(:logout_error, locals:{logged_in:logged_in, admin:admin})
  else
    slim(:register, locals:{logged_in:logged_in, admin:admin})
  end
end

# Displays a login form
#
get('/showlogin') do
  if logged_in
    slim(:logout_error, locals:{logged_in:logged_in, admin:admin})
  else
    slim(:login, locals:{logged_in:logged_in, admin:admin})
  end
end

# Attempts login and update session
#
# @param username [String] The username
# @param password [String] The password
#
# @see Model#checkLogin
# @see Model#getUserId
# @see Model#getRole
#
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
    login_attempts += 1
    session[:last_login] = Time.now.to_f
    redirect('/passerror')
  end
end

# Displays a users activities
#
# @see Model#getActivities
get('/activities') do
  if logged_in
    id = session[:id].first["id"]
    activities = getActivities(id)
    slim(:"activities/index", locals:{activities:activities, logged_in:logged_in, admin:admin})
  else
    slim(:login_error, locals:{activities:activities, logged_in:logged_in})
  end
end

# Deletes an existing activity and redirects to '/activities'
#
# @param :id [Integer] the ID of the activity
#
# @see Model#deleteActivity
post('/activities/:id/delete') do
  id = params[:id].to_i
  deleteActivity(id)
  redirect('/activities')
end

# Creates a new activity and redirects to '/activities' and updates user's milestones
#
# @param name [String] The name of the acitivity
# @param time [Float] The time spent on activity
#
# @see Model#getMilestones
# @see Model#updateMilestones
# @see Model#createActivity

post('/activities') do
  name = params[:name]
  time = params[:time]
  if name == "" || time == ""
    p "error"
    redirect('/activities')
  end
  milestones = getMilestones(session[:id].first["id"])
  updateMilestones(session[:id].first["id"], time, milestones)
  createActivity(name, session[:id].first["id"], time)
  redirect('/activities')
end

# Updates an existing activity and redirects to '/activities' and updates user's milestones
#
# @param :id [Integer] The ID of the activity
# @param name [String] The new name of the activity
# @param time [Float] The new time spent on activity
#
# @see Model#updateActivity
# @see Model#getMilestones
# @see Model#updateMilestones
post('/activities/:id/update') do
  id = params[:id].to_i
  name = params[:name]
  time = params[:time]
  updateActivity(name, time, id)
  milestones = getMilestones(session[:id].first["id"])
  updateMilestones(session[:id].first["id"], time, milestones)
  redirect('/activities')
end

# Displays update form for activity
#
# @param :id [Integer] the ID of the activity
#
# @see Model#getDate
# @see Model#editActivity
get('/activities/:id/edit') do
  id = params[:id].to_i
  time = getDate(session[:id].first()["id"]).first()["birthday"]
  result = editActivity(id)
  if logged_in
    slim(:"/activities/edit", locals:{result:result, logged_in:logged_in, admin:admin, time:time})
  else
    slim(:login_error, locals:{result:result, logged_in:logged_in, admin:admin, username:session["username"]})
  end
end

# Attempts login and updates the session
#
# @param username [String] The username
# @param password [String] The password
# @param password_confirm [String] The repeated password
#
# @see Model#registerUser
# @see Model#getUserId
post('/users') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if username == "" || password == "" || password_confirm == ""
    p "error"
    redirect('/register')
  end

  if password == password_confirm
    registerUser(username, password)
    session[:id] = getUserId(username)
    logged_in = true
    session[:username] = username
    redirect('/')
  else
    "Lösenorden matchade inte"
  end
end

# Displays a single user
#
# @param :id [Integer] the ID of the user
#
# @see Model#getUser
# @see Model#showMilestones
# @see Model#allMilestones
# @see Model#getDate
get('/user/:id') do
  id = params[:id].to_i
  user = getUser(id)
  milestones = showMilestones(id)
  allmile = allMilestones()
  time = getDate(id).first()["birthday"]
  if time != nil
    date = Time.at(time).strftime('%Y-%m-%d')
  else
    date = nil
  end
  if logged_in
    slim(:"users/user", locals:{logged_in:logged_in, username:user["username"], milestones:milestones, allmile:allmile, admin:admin, user:user, date:date})
  else
    slim(:login_error, locals:{logged_in:logged_in, username:user["username"], milestones:milestones, allmile:allmile})
  end
end

# Attempts logut and destroys the session
#
post('/logout') do
  logged_in = false
  admin = false
  session.destroy
  redirect('/')
end

# Displays admin panel
#
# @see Model#getUsers
get('/admin') do
  if logged_in && admin
    users = getUsers()
    slim(:admin, locals:{logged_in:logged_in, admin:admin, users:users})
  else
    slim(:login_error, locals:{logged_in:logged_in})
  end
end

# Displays members list
#
# @see Model#getUsers
get('/members') do
  if logged_in
    users = getUsers()
    slim(:"users/members", locals:{logged_in:logged_in, admin:admin, users:users})
  else
    slim(:login_error, locals:{logged_in:logged_in})
  end
end

# Deletes an existing user and redirects to '/admin'
#
# @param :id [Integer] The ID of the user
#
# @see Model#deleteUser
post('/users/:id/delete') do
  id = params[:id].to_i
  deleteUser(id)
  redirect('/admin')
end

# Updates an existing user and redirects to '/admin'
#
# @param :id [Integer] The ID of the user
# @param role [String] The role of the user
#
# @see Model#editUser
post('/users/:id/edit') do
  id = params[:id].to_i
  role = params[:role]
  editUser(id, role)
  redirect('/admin')
end

# Displays an error message
#
get('/passerror') do
  slim(:wrong_password, locals:{logged_in:logged_in})
end

# Updates an existing user and redirects to '/user/:id'
#
# @param :id [Integer] The ID of the user
# @param tmpDate [String] The birthday of the user
#
# @see Model#updateBirthday
post('/user/:id/update') do
  id = params[:id].to_i
  tmpDate = params[:birthday].split('-')
  beginDate = Time.new(*tmpDate).to_f
  endDate = Time.new.to_f
  session[:time] = endDate - beginDate
  updateBirthday(beginDate, id)
  redirect("/user/#{id}")
end