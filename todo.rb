require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"

require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

helpers do
  def success_list_removal
    session[:success] = "The list has been successfully deleted."
  end

  def set_session_success_message(message)
    session[:success] = message
  end

  def set_session_error_message(error)
    session[:error] = error
  end

  def all_todos_completed?(list)
    list.all? { |todo| todo[:completed] == true } && list.size > 0
  end

  def list_class(list)
    "complete" if all_todos_completed?(list)
  end

  # displays the number of completed todos out of the total todos
  def display_num_completed_todos(list)
    num_completed = list.select { |todo| todo[:completed] == true }.size
    total_todos = list.size

    "#{num_completed}/#{total_todos}"
  end

  # sorts the todos lists by those that are completed
  def sort_list_of_todos(list)
    list.sort_by do |list|
      all_todos_completed?(list[:todos]) ? 0 : 1
    end
  end

  def sort_todo_list_by_completed!(list)
    list[:todos].sort_by! do |todo|
      todo[:completed] == true ? 0 : 1
    end

    list
  end

  # checks to see if all todos are completed
  def all_todos_completed?(list)
    list.all? { |todo| todo[:completed] == true } && list.size > 0
  end
end

def load_list(id)
  list = @storage.find_list(id)
  return list if list
  error_msg = "The specified list was not found."

  set_session_error_message(error_msg)
  redirect "/lists"
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif @storage.all_lists.any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo must be between 1 and 100 characters."
  end
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = @storage.all_lists
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    set_session_error_message(error)
    erb :new_list, layout: :layout
  else
    success = "The list has been created"
    @storage.create_new_todo_list(list_name)
    set_session_success_message(success)
    redirect "/lists" 
  end
end

# View a single todo list
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = load_list(id)
  erb :edit_list, layout: :layout
end

# Update an existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = load_list(id)

  error = error_for_list_name(list_name)
  if error
    set_session_error_message(error)
    erb :edit_list, layout: :layout
  else
    @storage.update_list_name(id, list_name)
    success = "The list has been updated."
    set_session_success_message(success)
    redirect "/lists/#{id}"
  end
end

# Delete a todo list
post "/lists/:id/destroy" do
  id = params[:id].to_i
  success = "The list has been deleted."
  @storage.delete_todo_list(id)
  set_session_success_message(success)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    redirect "/lists"
  end
end

# Add a new todo to a list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_name = params[:todo].strip

  error = error_for_todo(todo_name)
  if error
    set_session_error_message(error)
    erb :list, layout: :layout
  else
    success = "The todo was added."
    @storage.create_new_todo(@list_id, todo_name)
    set_session_success_message(success)
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:id].to_i
  @storage.delete_todo_from_list(@list_id, todo_id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    success = "The todo has been deleted."
    set_session_success_message(success)
    redirect "/lists/#{@list_id}"
  end
end

# Update the status of a todo
post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  success = "The todo has been updated."

  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @storage.update_todo_status(@list_id, todo_id, is_completed)

  set_session_success_message(success)
  redirect "/lists/#{@list_id}"
end

# Mark all todos as complete for a list
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  success = "All todos have been completed."

  @storage.mark_all_todos_complete(@list_id)

  set_session_success_message(success)
  redirect "/lists/#{@list_id}"
end
