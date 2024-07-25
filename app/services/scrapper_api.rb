require 'httparty'
require 'json'

class ScrapperApi
  ALGOLIA_API_URL = 'https://45bwzj1sgc-dsn.algolia.net/1/indexes/YCCompany_production/query'
  ALGOLIA_API_KEY = 'MjBjYjRiMzY0NzdhZWY0NjExY2NhZjYxMGIxYjc2MTAwNWFkNTkwNTc4NjgxYjU0YzFhYTY2ZGQ5OGY5NDMxZnJlc3RyaWN0SW5kaWNlcz0lNUIlMjJZQ0NvbXBhbnlfcHJvZHVjdGlvbiUyMiUyQyUyMllDQ29tcGFueV9CeV9MYXVuY2hfRGF0ZV9wcm9kdWN0aW9uJTIyJTVEJnRhZ0ZpbHRlcnM9JTVCJTIyeWNkY19wdWJsaWMlMjIlNUQmYW5hbHl0aWNzVGFncz0lNUIlMjJ5Y2RjJTIyJTVE'
  ALGOLIA_APP_ID = '45BWZJ1SGC'

  def initialize(n, filters = {})
    @n = n
    @filters = filters
    @companies = []
  end

  def scrape_company_data
    current_page = 0
    hits_per_page = 10

    # set company size object
    # if @filters[:company_size].include?("-")
    #   company_size = @filters[:company_size].split("-")
    #   min_company_size = company_size[0].to_i
    #   max_company_size = company_size[1].to_i
    # else
    #   min_company_size = 1
    #   maximum_company_size = @filters[:company_size].to_i
    # end

    while @companies.size < @n
      response = HTTParty.post(
        ALGOLIA_API_URL,
        headers: {
          'Content-Type' => 'application/json',
          'X-Algolia-API-Key' => ALGOLIA_API_KEY,
          'X-Algolia-Application-Id' => ALGOLIA_APP_ID
        },
        body: {
          facetFilters: build_filters,
          facetQuery: "",
          facets: [
            'app_answers', 'app_video_public', 'batch', 'demo_day_video_public', 'highlight_black',
            'highlight_latinx', 'highlight_women', 'industries', 'isHiring', 'nonprofit', 'question_answers',
            'regions', 'subindustry', 'tags', 'top_company'
          ],
          hitsPerPage: hits_per_page,
          maxFacetHits: 100,
          maxValuesPerFacet: 1000,
          page: current_page,
          query: ""
        }.to_json
      )

      if response.code != 200
        raise "Failed to fetch data: #{response.message}"
      end

      results = JSON.parse(response.body)['hits']

      break if results.nil? || results.empty?

      results.each do |company|
        break if @companies.size >= @n

        name = company['name']
        location = company['all_locations']
        description = company['one_liner']
        batch = company['batch']
        website = company['website']
        founders = company.dig('founders')&.map { |f| f['name'] } || []
        linkedin_urls = company.dig('founders')&.map { |f| f['linkedin_url'] } || []

        @companies << {
          name: name,
          location: location,
          description: description,
          batch: batch,
          website: website,
          # object_id: company['objectID'],
          founders: founders.join(', '),
          linkedin_urls: linkedin_urls.join(', ')
        }
      end

      current_page += 1
    end

    @companies
  end

  #export data to csv format
  def export_csv
    CSV.generate(headers: true) do |csv|
      csv << %w[name location description batch website founders linkedin_urls]

      @companies.each do |company|
        csv << company.values
      end
    end
  end

  private

  def build_filters
    @filters = @filters.to_h
    # map keys with actual parameters passed with api parameters
    filter_mapping = {
      "industry" => "industries",
      "region" => "regions",
      "tag" => "top_company",
      "company_size" => "company_size",
      "is_hiring" => "isHiring",
      "nonprofit" => "nonprofit",
      "black_founded" => "highlight_black",
      "hispanic_latino_founded" => "highlight_latinx",
      "women_founded" => "highlight_women",
      "batch" => "batch"
    }

    @filters.map do |key, value|
      mapped_key = filter_mapping[key]
      ["#{mapped_key}:#{value}"]
    end
  end
end