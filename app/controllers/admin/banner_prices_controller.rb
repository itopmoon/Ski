class Admin::BannerPricesController < ApplicationController
  before_action :admin_required

  before_action :set_banner_price, only: [:edit, :update, :destroy]

  layout 'admin'

  def index
    @banner_prices = BannerPrice.all
  end

  def new
    @banner_price = BannerPrice.new
  end

  def create
    @banner_price = BannerPrice.new(banner_price_params)
    if @banner_price.save
      redirect_to admin_banner_prices_path, notice: t('notices.created')
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @banner_price.update_attributes(banner_price_params)
      redirect_to admin_banner_prices_path, notice: t('notices.saved')
    else
      render 'edit'
    end
  end

  def destroy
    @banner_price.destroy
    redirect_to admin_banner_prices_path, notice: t('notices.deleted')
  end

  protected

    def set_banner_price
      @banner_price = BannerPrice.find(params[:id])
    end

    def banner_price_params
      params.require(:banner_price).permit(:current_banner_number, :price)
    end
end