require File.dirname(__FILE__) + '/../test_helper'
require 'environments_controller'

# Re-raise errors caught by the controller.
class EnvironmentsController; def rescue_action(e) raise e end; end

class EnvironmentsControllerTest < Test::Unit::TestCase
  fixtures :environments

  def setup
    @controller = EnvironmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:environments)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_environment
    old_count = Environment.count
    post :create, :environment => { }
    assert_equal old_count+1, Environment.count
    
    assert_redirected_to environment_path(assigns(:environment))
  end

  def test_should_show_environment
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_environment
    put :update, :id => 1, :environment => { }
    assert_redirected_to environment_path(assigns(:environment))
  end
  
  def test_should_destroy_environment
    old_count = Environment.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Environment.count
    
    assert_redirected_to environments_path
  end
end
