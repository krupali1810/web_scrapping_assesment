class YcscraperController < ApplicationController
  skip_before_action :verify_authenticity_token
  def scrape
    n = params[:n].to_i
    filters = params[:filters]&.permit(:batch, :industry, :region, :tag, :company_size, :is_hiring, :nonprofit, :black_founded, :hispanic_latino_founded, :women_founded).to_h || {}

    scraper = ScrapperApi.new(n, filters)
    companies = scraper.scrape_company_data

    csv_data = scraper.export_csv

    respond_to do |format|
      format.csv { send_data csv_data, filename: "yc_companies_#{Time.now.to_i}.csv" }
    end
  end
end