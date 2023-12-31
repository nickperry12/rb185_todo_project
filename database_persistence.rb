require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "todos")
          end
    @logger = logger
  end

  def disconnect
    db.close
  end
  
  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1"
    result = query(sql, id)
  
    tuple = result.first
    {id: tuple["id"], name: tuple["name"], todos: query_todos(id)}
  end

  def all_lists
    sql = "SELECT * FROM lists"
    todo_query = "SELECT name FROM todos WHERE list_id = $1"
    list_result = query(sql)
    todo_result = query(sql)

    list_result.map do |tuple|
      list_id = tuple["id"]
      {id: list_id, name: tuple["name"], todos: query_todos(list_id)}
    end
  end

  def delete_todo_list(id)
    sql = "DELETE FROM lists WHERE id = $1"
    query(sql, id)
  end

  def create_new_todo_list(*list_name)
    sql = "INSERT INTO lists (name) VALUES ($1)"
    db.exec_params(sql, list_name)
  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2"
    query(sql, new_name, id)
  end

  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos (list_id, name) VALUES ($1, $2)"
    query(sql, list_id, todo_name)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE list_id = $1 AND id = $2"
    query(sql, list_id, todo_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = "UPDATE todos SET completed = $1 WHERE list_id = $2 AND id = $3"
    query(sql, new_status, list_id, todo_id)
  end

  def mark_all_todos_complete(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1"
    query(sql, list_id)
  end

  private

  def query(statement, *params)
    logger.info("#{statement}: #{params}")
    db.exec_params(statement, params)
  end

  def query_todos(*list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1"
    result = db.exec_params(sql, list_id)
    result.map do |todo_tuple|
      completed = todo_tuple["completed"] == "t"

      {id: todo_tuple["id"],
        name: todo_tuple["name"],
        completed: completed,
        list_id: todo_tuple["list_id"]
      }
    end
  end

  attr_reader :db, :logger
end
