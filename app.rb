require 'sinatra'
require 'slim'

require_relative './model/model'
include Model

# https://github.com/pure-css/pure/blob/master/site/static/layouts/marketing/index.html
# https://purecss.io/layouts/marketing/

# Test account: {Username: Bob, Password: 7}

enable :sessions
logged_in = false
admin = false

# Display landing page
#
get('/') do
  slim(:index, locals: { logged_in: logged_in, admin: admin })
end

# Displays a register form
#
get('/register') do
  if logged_in
    slim(:logout_error, locals: { logged_in: logged_in, admin: admin })
  else
    slim(:register, locals: { logged_in: logged_in, admin: admin })
  end
end

# Displays a login form
#
get('/showlogin') do
  if logged_in
    slim(:logout_error, locals: { logged_in: logged_in, admin: admin })
  else
    slim(:login, locals: { logged_in: logged_in, admin: admin })
  end
end

# Attempts login and update session
#
# @param [String] username The username
# @param [String] password The password
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
    role = getRole(session[:id].first['id']).first['role']
    admin = true if role == 'admin'
    redirect('/activities')
  else
    logged_in = false
    session[:last_failed_login] = Time.now.to_i
    redirect('/passerror')
  end
end

# Displays a users activities
#
# @see Model#getActivities
get('/activities') do
  if logged_in
    id = session[:id].first['id']
    activities = getActivities(id)
    slim(:"activities/index", locals: { activities: activities, logged_in: logged_in, admin: admin })
  else
    slim(:login_error, locals: { activities: activities, logged_in: logged_in })
  end
end

# Deletes an existing activity and redirects to '/activities'
#
# @param [Integer] :id the ID of the activity
#
# @see Model#deleteActivity
post('/activities/:id/delete') do
  id = params[:id].to_i
  deleteActivity(id)
  redirect('/activities')
end

# Creates a new activity and redirects to '/activities' and updates user's milestones
#
# @param [String] name The name of the acitivity
# @param [Float] time The time spent on activity
#
# @see Model#getMilestones
# @see Model#updateMilestones
# @see Model#createActivity

post('/activities') do
  name = params[:name]
  time = params[:time]
  if name == '' || time == ''
    p 'error'
    redirect('/activities')
  end
  milestones = getMilestones(session[:id].first['id'])
  updateMilestones(session[:id].first['id'], time, milestones)
  createActivity(name, session[:id].first['id'], time)
  redirect('/activities')
end

# Updates an existing activity and redirects to '/activities' and updates user's milestones
#
# @param [Integer] :id The ID of the activity
# @param [String] name The new name of the activity
# @param [Float] time The new time spent on activity
#
# @see Model#updateActivity
# @see Model#getMilestones
# @see Model#updateMilestones
post('/activities/:id/update') do
  id = params[:id].to_i
  name = params[:name]
  time = params[:time]
  updateActivity(name, time, id)
  milestones = getMilestones(session[:id].first['id'])
  updateMilestones(session[:id].first['id'], time, milestones)
  redirect('/activities')
end

# Displays update form for activity
#
# @param [Integer] :id the ID of the activity
#
# @see Model#getDate
# @see Model#editActivity
get('/activities/:id/edit') do
  id = params[:id].to_i
  time = getDate(session[:id].first['id']).first['birthday']
  result = editActivity(id)
  if logged_in
    slim(:"/activities/edit", locals: { result: result, logged_in: logged_in, admin: admin, time: time })
  else
    slim(:login_error, locals: { result: result, logged_in: logged_in, admin: admin, username: session['username'] })
  end
end

# Attempts login and updates the session
#
# @param [String] username The username
# @param [String] password The password
# @param [String] password_confirm The repeated password
#
# @see Model#registerUser
# @see Model#getUserId
post('/users') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if username == '' || password == '' || password_confirm == ''
    p 'error'
    redirect('/register')
  end

  if password == password_confirm
    registerUser(username, password)
    session[:id] = getUserId(username)
    logged_in = true
    session[:username] = username
    redirect('/')
  else
    'Lösenorden matchade inte'
  end
end

# Displays a single user
#
# @param [Integer] :id the ID of the user
#
# @see Model#getUser
# @see Model#showMilestones
# @see Model#allMilestones
# @see Model#getDate
get('/user/:id') do
  id = params[:id].to_i
  user = getUser(id)
  milestones = showMilestones(id)
  allmile = allMilestones
  time = getDate(id).first['birthday']
  date = (Time.at(time).strftime('%Y-%m-%d') if time)
  if logged_in
    slim(:"users/user",
         locals: { logged_in: logged_in, username: user['username'], milestones: milestones, allmile: allmile, admin: admin,
                   user: user, date: date })
  else
    slim(:login_error,
         locals: { logged_in: logged_in, username: user['username'], milestones: milestones, allmile: allmile })
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
    users = getUsers
    slim(:admin, locals: { logged_in: logged_in, admin: admin, users: users })
  else
    slim(:login_error, locals: { logged_in: logged_in })
  end
end

# Displays members list
#
# @see Model#getUsers
get('/members') do
  if logged_in
    users = getUsers
    slim(:"users/members", locals: { logged_in: logged_in, admin: admin, users: users })
  else
    slim(:login_error, locals: { logged_in: logged_in })
  end
end

# Deletes an existing user and redirects to '/admin'
#
# @param [Integer] :id The ID of the user
#
# @see Model#deleteUser
post('/users/:id/delete') do
  id = params[:id].to_i
  deleteUser(id)
  redirect('/admin')
end

# Updates an existing user and redirects to '/admin'
#
# @param [Integer] :id The ID of the user
# @param [String] role The role of the user
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
  slim(:wrong_password, locals: { logged_in: logged_in })
end

# Updates an existing user and redirects to '/user/:id'
#
# @param [Integer] :id The ID of the user
# @param [String] tmpDate The birthday of the user
#
# @see Model#updateBirthday
post('/user/:id/update') do
  id = params[:id].to_i
  tmp_date = params[:birthday].split('-')
  begin_date = Time.new(*tmp_date).to_i
  updateBirthday(begin_date, id)
  redirect("/user/#{id}")
end
