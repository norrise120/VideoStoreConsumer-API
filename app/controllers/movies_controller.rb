class MoviesController < ApplicationController
  before_action :require_movie, only: [:show]

  def index
    if params[:query]
      data = MovieWrapper.search(params[:query])
    else
      data = Movie.all
    end

    render status: :ok, json: (data.map {
        |movie|
        movie.as_json(
          only: [:id, :external_id, :title, :overview, :release_date, :inventory, :image_url],
          methods: [:available_inventory],
        )
      })
  end

  def create
    movie = Movie.find_by(external_id: params[:external_id])
    if movie
      movie.inventory = movie.inventory + params[:inventory].to_i
    else
      movie = Movie.new(movie_params)
    end
    success = movie.save

    if success
      render status: :ok, json: movie.as_json(only: [:id, :title, :overview, :release_date, :image_url, :inventory], methods: [:available_inventory])
    else
      render status: :bad_request, json: { errors: movie.errors.messages }
    end
  end

  def show
    render(
      status: :ok,
      json: @movie.as_json(
        only: [:title, :overview, :release_date, :inventory],
        methods: [:available_inventory],
      ),
    )
  end

  private

  def require_movie
    @movie = Movie.find_by(title: params[:title])
    unless @movie
      render status: :not_found, json: { errors: { title: ["No movie with title #{params["title"]}"] } }
    end
  end

  def movie_params
    params.require(:movie).permit(:title, :overview, :inventory, :release_date, :image_url, :external_id)
  end
end
