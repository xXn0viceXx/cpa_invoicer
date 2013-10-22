class AddDonors < ActiveRecord::Migration
  def change
    create_table :donors do |t|
      t.string :donor_no
      t.string :initials
      t.string :surname
      t.string :title
      t.timestamps
    end
  end
end
