class Invoice
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper

  attr_reader :filename

  def initialize(order)
    @order = order
  end

  def render
    dir = "#{Rails.root.to_s}/public/invoices/#{@order.hash.to_s}"
    FileUtils.makedirs(dir)
    @filename = "#{dir}/MCF-Invoice-#{@order.order_number}.pdf"

    Prawn::Document.generate(filename, page_size: 'A4') do |pdf|
      spacing = 3
      pdf.font 'fonts/Aller_Lt.ttf'
      pdf.font_size 18
      pdf.text "Invoice number #{@order.order_number}"
      pdf.move_down 24
      pdf.font_size 10
      pdf.text "Invoice created at: #{@order.created_at}"
      pdf.move_down 24

      address_top = 700

      pdf.bounding_box([0, address_top], width: 200, height: 200) do
        pdf.text "My Holiday Home Ventures Ltd\n14 Murrayfield Drive\nEdinburgh\nMidlothian\nEH12 6EB\nUnited Kingdom\nCompany no. SC391840\nVAT no. 111 7832 38", leading: 4
      end

      pdf.bounding_box([300, address_top], width: 200, height: 200) do
        pdf.text("Customer:\n" + @order.user.business_name + "\n" + @order.address.strip + "\n" + @order.postcode + "\n" + @order.country.to_s + "\nCustomer VAT number: #{@order.customer_vat_number}", leading: 4)
      end

      cells = []
      headers = ["Product", "Price"]
      headers <<= 'Sterling' if @order.sterling_in_euros 
      cells << headers
      @order.order_lines.each do |line|
        cells << [line.description, euros_from_cents(line.amount)]
      end
      tax_line = [@order.tax_description, euros_from_cents(@order.tax_amount)]
      tax_line <<= @order.tax_amount / @order.sterling_in_euros if @order.sterling_in_euros
      cells << tax_line
      total_line = ["Order total:", euros_from_cents(@order.total)]
      total_line <<= @order.total / @order.sterling_in_euros if @order.sterling_in_euros
      cells << total_line

      t = Prawn::Table.new(cells, pdf)
      t.draw

      if @order.sterling_in_euros
        pdf.move_down 24
        pdf.text "1 GBP = #{@order.sterling_in_euros} EUR"
      end

      logopath = "#{Rails.root.to_s}/public/images/my-chalet-finder-logo.png"
      pdf.bounding_box([300, 770], width: 126, height: 22) do
        pdf.image logopath, width: 126, height: 22
      end
    end
  end
end