class ResortsController < ApplicationController
  before_filter :admin_required, :except => [:show, :directory, :feature, :featured, :piste_map, :detail]
  before_filter :find_resort, :only => [:edit, :update, :show, :destroy, :detail, :directory, :feature, :piste_map]
  before_filter :no_browse_menu, :except => [:show, :feature, :directory]

  def index
    @countries = Country.with_resorts
  end

  def new
    @resort = Resort.new
    @resort.country_id = session[:last_country_id] unless session[:last_country_id].nil?
  end

  def create
    @resort = Resort.new(params[:resort])

    respond_to do |format|
      if @resort.save
        session[:last_country_id] = @resort.country_id
        format.html { redirect_to(resorts_path, :notice => 'Resort created.') }
        format.xml  { render :xml => @resort, :status => :created, :location => @resort }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @resort.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @resort.update_attributes(params[:resort])
        format.html { redirect_to(resorts_path, :notice => 'Saved') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @resort.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @stage_heading_a = I18n.t('stage_1_inactive')
    @stage_heading_b = I18n.t('stage_2')
    @heading_a = @resort.name + ' Resort Information'
  end

  def destroy
    @resort.destroy

    respond_to do |format|
      format.html { redirect_to(resorts_url) }
      format.xml  { head :ok }
    end
  end

  def detail
    @heading_a = render_to_string(:partial => 'detail_heading').html_safe
  end

  def directory
    @heading_a = "Directory for #{@resort.name}, #{@resort.country.name}"
    @categories = Category.order(:name).all
  end

  def featured
    @heading_a = I18n.t('featured_resorts')
  end

  def piste_map
    @heading_a = I18n.t('piste_map')
  end

  def feature
  end

  protected

  def find_resort
    @resort = Resort.find_by_id(params[:id])
    redirect_to(resorts_path, :notice => 'That resort does not exist.') unless @resort
  end
end
