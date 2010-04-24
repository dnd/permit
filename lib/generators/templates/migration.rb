class CreatePermitStructure < ActiveRecord::Migration
  def self.up
    create_table :<%=role_class.tableize%> do |t|
      t.string :key, :name, :null => false
      t.string :description
      t.boolean :requires_resource, :authorize_resource, :null => false, :default => true
    end

    add_index :<%=role_class.tableize%>, :key, :unique => true

    create_table :<%=authorization_class.tableize%> do |t|
      t.integer :<%=person_class.underscore%>_id, :<%=role_class.underscore%>_id, :null => false
      t.string :resource_type
      t.integer :resource_id
      t.timestamps
    end

    add_index :<%=authorization_class.tableize%>, :<%=person_class.underscore%>_id
    add_index :<%=authorization_class.tableize%>, :<%=role_class.underscore%>_id
    add_index :<%=authorization_class.tableize%>, [:<%=person_class.underscore%>_id, :<%=role_class.underscore%>_id, :resource_type, :resource_id], :unique => true, :name => '<%=authorization_class.tableize%>_idx_uniq'
  end

  
  def self.down
    drop_table :<%=authorization_class.tableize%>
    drop_table :<%=role_class.tableize%>
  end
end
