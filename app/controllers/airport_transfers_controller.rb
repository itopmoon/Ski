AirportTransferSearch = Struct.new(:airport_id, :resort_id)

class AirportTransfersController < ApplicationController
  before_filter :no_browse_menu
  before_filter :user_required

  def index
    default_page_title(@heading_a = t('airport_transfers_controller.titles.index'))
    @airport_transfers = @current_user.airport_transfers
  end

  def create
    params[:transfers][:resort_id].each do |resort_id|
      at = AirportTransfer.new
      at.airport_id = params[:transfers][:airport_id]
      at.resort_id = resort_id
      at.user = @current_user
      at.save
    end
    redirect_to airport_transfers_path, notice: t('notices.added')
  end

  def destroy
    at = AirportTransfer.find(params[:id])
    if at && at.user == @current_user
      at.destroy
    end
    redirect_to airport_transfers_path, notice: t('notices.deleted')
  end

  def find
    @heading_a = 'Find Airport Transfers'
    default_page_title(@heading_a)
    @airport_transfer_search = AirportTransferSearch.new
  end

  def results
    @heading_a = 'Find Airport Transfers'
    default_page_title(@heading_a)
    airport_id, resort_id = params[:airport_transfer_search][:airport_id],
      params[:airport_transfer_search][:resort_id]

    unless airport_id.blank? or resort_id.blank?
      @airport = Airport.find(airport_id)
      @resort = Resort.find(resort_id)
      airport_transfers = AirportTransfer.all(conditions: ["airport_id = ? AND resort_id = ?", airport_id, resort_id])

      @results = []
      airport_transfers.each do |t|
        ad = t.user.airport_transfer_banner_advert
        @results << ad unless ad.nil?
      end
    end

    @airport_transfer_search = AirportTransferSearch.new(
      params[:airport_transfer_search][:airport_id],
      params[:airport_transfer_search][:resort_id]
    )
    render 'find'
  end
end
