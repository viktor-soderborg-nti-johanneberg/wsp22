require 'sinatra'
require 'slim'

require_relative './model/model'
include Model

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
# @see Model#check_login
# @see Model#get_user_id
# @see Model#get_role
#
post('/login') do
  username = params[:username]
  password = params[:password]
  if check_login(username, password)
    session[:id] = get_user_id(username)
    session[:username] = username
    logged_in = true
    role = get_role(session[:id].first['id']).first['role']
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
# @see Model#get_activities
get('/activities') do
  if logged_in
    id = session[:id].first['id']
    activities = get_activities(id)
    slim(:"activities/index", locals: { activities: activities, logged_in: logged_in, admin: admin })
  else
    slim(:login_error, locals: { activities: activities, logged_in: logged_in })
  end
end

# Deletes an existing activity and redirects to '/activities'
#
# @param [Integer] :id the ID of the activity
#
# @see Model#delete_activity
post('/activities/:id/delete') do
  activity_info = edit_activity(params[:id].to_i)
  if logged_in && session[:id].first['id'] == activity_info['user_id']
    id = params[:id].to_i
    delete_activity(id)
    redirect('/activities')
  end
end

# Creates a new activity and redirects to '/activities' and updates user's milestones
#
# @param [String] name The name of the acitivity
# @param [Float] time The time spent on activity
#
# @see Model#get_milestones
# @see Model#update_milestones
# @see Model#create_activity

post('/activities') do
  if logged_in
    name = params[:name]
    time = params[:time]
    if name == '' || time == ''
      p 'error'
      redirect('/activities')
    end
    milestones = get_milestones(session[:id].first['id'])
    update_milestones(session[:id].first['id'], time, milestones)
    create_activity(name, session[:id].first['id'], time)
    redirect('/activities')
  end
end

# Updates an existing activity and redirects to '/activities' and updates user's milestones
#
# @param [Integer] :id The ID of the activity
# @param [String] name The new name of the activity
# @param [Float] time The new time spent on activity
#
# @see Model#update_activity
# @see Model#get_milestones
# @see Model#update_milestones
post('/activities/:id/update') do
  activity_info = edit_activity(params[:id].to_i)
  if logged_in && session[:id].first['id'] == activity_info['user_id']
    id = params[:id].to_i
    name = params[:name]
    time = params[:time]
    update_activity(name, time, id)
    milestones = get_milestones(session[:id].first['id'])
    update_milestones(session[:id].first['id'], time, milestones)
    redirect('/activities')
  end
end

# Displays update form for activity
#
# @param [Integer] :id the ID of the activity
#
# @see Model#get_date
# @see Model#edit_activity
get('/activities/:id/edit') do
  id = params[:id].to_i
  time = get_date(session[:id].first['id']).first['birthday']
  result = edit_activity(id)
  if logged_in && session[:id].first['id'] == result['user_id']
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
# @see Model#register_user
# @see Model#get_user_id
post('/users') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if username == '' || password == '' || password_confirm == ''
    p 'error'
    redirect('/register')
  end

  if password == password_confirm
    register_user(username, password)
    session[:id] = get_user_id(username)
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
# @see Model#get_user
# @see Model#show_milestones
# @see Model#all_milestones
# @see Model#get_date
get('/user/:id') do
  id = params[:id].to_i
  user = get_user(id)
  milestones = show_milestones(id)
  allmile = all_milestones
  time = get_date(id).first['birthday']
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
# @see Model#get_users
get('/admin') do
  if logged_in && admin
    users = get_users
    slim(:admin, locals: { logged_in: logged_in, admin: admin, users: users })
  else
    slim(:login_error, locals: { logged_in: logged_in })
  end
end

# Displays members list
#
# @see Model#get_users
get('/members') do
  if logged_in
    users = get_users
    slim(:"users/members", locals: { logged_in: logged_in, admin: admin, users: users })
  else
    slim(:login_error, locals: { logged_in: logged_in })
  end
end

# Deletes an existing user and redirects to '/admin'
#
# @param [Integer] :id The ID of the user
#
# @see Model#delete_user
post('/users/:id/delete') do
  if logged_in && admin
    id = params[:id].to_i
    delete_user(id)
    redirect('/admin')
  end
end

# Updates an existing user and redirects to '/admin'
#
# @param [Integer] :id The ID of the user
# @param [String] role The role of the user
#
# @see Model#edit_user
post('/users/:id/edit') do
  id = params[:id].to_i
  if logged_in && session[:id].first['id'] == id
    role = params[:role]
    edit_user(id, role)
    redirect('/admin')
  end
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
# @see Model#update_birthday
post('/user/:id/update') do
  id = params[:id].to_i
  if logged_in && session[:id].first['id'] == id
    tmp_date = params[:birthday].split('-')
    begin_date = Time.new(*tmp_date).to_i
    update_birthday(begin_date, id)
    redirect("/user/#{id}")
  end
end
