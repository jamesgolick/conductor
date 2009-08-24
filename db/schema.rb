# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090824184649) do

  create_table "applications", :force => true do |t|
    t.string   "name"
    t.string   "clone_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cookbook_clone_url"
  end

  create_table "chef_logs", :force => true do |t|
    t.integer  "instance_id"
    t.boolean  "successful"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.string   "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deployments", :force => true do |t|
    t.string   "type"
    t.integer  "instance_id"
    t.text     "log"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "exit_code"
  end

  create_table "environments", :force => true do |t|
    t.integer  "application_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "domain"
  end

  create_table "instances", :force => true do |t|
    t.integer  "environment_id"
    t.string   "size"
    t.string   "zone"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "instance_id"
    t.string   "config_state"
    t.string   "dns_name"
    t.string   "private_dns_name"
    t.string   "aws_state"
  end

  create_table "volumes", :force => true do |t|
    t.integer  "environment_id"
    t.string   "role"
    t.integer  "instance_id"
    t.integer  "size"
    t.string   "zone"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
