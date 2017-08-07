class CreateIdentities < ActiveRecord::Migration[5.1]
  def change
    create_table :identities do |t|
      t.references :user, foreign_key: true
      t.string :provider
      t.string :access_token
      t.string :refresh_token
      t.string :uid
      t.string :name
      t.string :email
      t.string :nick_name
      t.string :image
      t.string :phone
      t.string :urls
      t.json :raw
      t.datetime :oauth_expires_at

      t.timestamps
    end
  end
end
