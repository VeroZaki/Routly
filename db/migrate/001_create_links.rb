class CreateLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :links do |t|
      t.string :original_url, null: false
      t.string :code, null: false
      t.timestamps
    end

    add_index :links, :code, unique: true
    add_index :links, :original_url
  end
end
