class YcscraperController < ApplicationController
  skip_before_action :verify_authenticity_token
  def scrape
    n = params[:n].to_i
    filters = params[:filters]&.permit(:batch, :industry, :region, :top_companies, :company_size, :is_hiring, :nonprofit, :black_founded, :hispanic_latino_founded, :women_founded).to_h || {}

    scraper = ScrapperApi.new(n, filters)
    companies = scraper.scrape_company_data

    if companies.empty?
      respond_to do |format|
        format.csv { render plain: "No data found for the given filters.", status: :not_found }
      end
    else
      csv_data = scraper.export_csv
      respond_to do |format|
        format.csv { send_data csv_data, filename: "yc_companies_#{Time.now.to_i}.csv" }
      end      
    end
  end
end