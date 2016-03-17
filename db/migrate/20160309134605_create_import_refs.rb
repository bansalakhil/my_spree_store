class CreateImportRefs < ActiveRecord::Migration
  def change
    create_table :import_refs do |t|
      t.string :shopify_type
      t.string :shopify_id
      t.string :spree_type
      t.string :spree_id

      t.timestamps null: false
    end
    
    add_index :import_refs, [:shopify_type, :shopify_id]
    add_index :import_refs, [:spree_type, :spree_id]    
  end
end
