require File.dirname(__FILE__) + '/../test_helper'
require 'applications_controller'

# Re-raise errors caught by the controller.
class ApplicationsController; def rescue_action(e) raise e end; end

class ApplicationsControllerTest < Test::Unit::TestCase
  fixtures :applications

  def setup
    @controller = ApplicationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:applications)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_application
    old_count = Application.count
    post :create, :application => { }
    assert_equal old_count+1, Application.count
    
    assert_redirected_to application_path(assigns(:application))
  end

  def test_should_show_application
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_application
    put :update, :id => 1, :application => { }
    assert_redirected_to application_path(assigns(:application))
  end
  
  def test_should_destroy_application
    old_count = Application.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Application.count
    
    assert_redirected_to applications_path
  end
end
