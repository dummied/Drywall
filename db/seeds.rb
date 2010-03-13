# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

Setting.create(:name => "site_name", :value => "Drywall")
Setting.create(:name => "site_description", :value => "Software made with soul")
Setting.create(:name => "articles_per_page", :value => 30)
Setting.create(:name => "home_url", :value => "")
Setting.create(:name => "run_once", :value => true)
