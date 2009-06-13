require File.dirname(__FILE__) + '/../test_helper'
require 'instances_controller'

# Re-raise errors caught by the controller.
class InstancesController; def rescue_action(e) raise e end; end

class InstancesControllerTest < Test::Unit::TestCase
  fixtures :instances

  def setup
    @controller = InstancesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:instances)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_instance
    old_count = Instance.count
    post :create, :instance => { }
    assert_equal old_count+1, Instance.count
    
    assert_redirected_to instance_path(assigns(:instance))
  end

  def test_should_show_instance
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_instance
    put :update, :id => 1, :instance => { }
    assert_redirected_to instance_path(assigns(:instance))
  end
  
  def test_should_destroy_instance
    old_count = Instance.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Instance.count
    
    assert_redirected_to instances_path
  end
end
