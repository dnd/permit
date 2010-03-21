class CreatePermitStructure < ActiveRecord::Migration
  create_table :<%=role_class.tableize%> do |t|
    t.string :key, :name, :description
    t.boolean :requires_resource, :authorize_resource, :null => false, :default => true
  end

  create_table :<%=authorization_class.tableize%> do |t|
    t.integer :<%=person_class.underscore%>_id, :<%=role_class.underscore%>_id, :null => false
    t.string :resource_type
    t.integer :resource_id
    t.timestamps
  end

end
