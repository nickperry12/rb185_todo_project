require "pg"

class DatabasePersistence
  def initialize
    @db = PG.connect(dbname: "todos")
  end
  
  def find_list(id)
    # session[:lists].find{ |list| list[:id] == id }
  end

  def all_lists
    sql = "SELECT * FROM lists"
    result = db.exec(sql)
    result.map do |tuple|
      {id: tuple["id"], name: tuple["name"], todos: []}
    end
  end

  def success_list_removal
    # session[:success] = "The list has been successfully deleted."
  end

  def set_session_success_message(message)
    # session[:success] = message
  end

  def set_session_error_message(error)
    # session[:error] = error
  end

  def delete_todo_list(id)
    # session[:lists].reject! { |list| list[:id] == id }
  end

  def create_new_todo_list(list_name)
    # id = next_element_id(@session[:lists])
    # session[:lists] << { id: id, name: list_name, todos: [] }
  end

  def update_list_name(id, new_name)
    # list = find_list(id)
    # list[:name] = new_name
  end

  def create_new_todo(list_id, todo_name)
    # list = find_list(list_id)
    # id = next_element_id(list[:todos])
    # list[:todos] << { id: id, name: todo_name, completed: false }
  end

  def delete_todo_from_list(list_id, todo_id)
    # list = find_list(list_id)
    # list[:todos].reject! { |todo| todo[:id] == todo_id }
  end

  def update_todo_status(list_id, todo_id, new_status)
    # list = find_list(list_id)
    # todo = list[:todos].find { |todo| todo[:id] == todo_id }
    # todo[:completed] = new_status
  end

  def mark_all_todos_complete(list_id)
    # list = find_list(list_id)
    # list[:todos].each do |todo|
    #   todo[:completed] = true
    # end
  end

  private

  attr_reader :db
end
