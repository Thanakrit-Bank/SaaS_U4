class MoviesController < ApplicationController
  before_action :authenticate_user!,except: [:index]

  skip_before_action :verify_authenticity_token 
  def index
    @movies = Movie.all
    @results = []
  end

  def show
    logger.debug @user
    id = params[:id] # retrieve movie ID from URI route
    begin
       @movie = Movie.find(id) # look up movie by unique ID
       # will render app/views/movies/show.html.haml by default
    rescue
      flash[:notice] = "Movie id #{id} not found."
      redirect_to movies_path
    end
  end

  def new
    # default: render 'new' template
    @movie = Movie.new
  end

  def create
    @movie = Movie.new(movie_params)
    if @movie.save
      flash[:notice] = "#{@movie.title} was successfully created."
      redirect_to movies_path
    else
      render 'new' # note, 'new' template can access @movie's field values!
    end
  end

  def edit
    @movie = Movie.find(params[:id])
  end
   
  def update
    @movie = Movie.find params[:id]
    if @movie.update(movie_params)
      flash[:notice] = "#{@movie.title} was successfully updated."
      redirect_to movie_path(@movie)
    else
      render 'edit' # note, 'edit' template can access @movie's field values!
    end
  end

  def destroy
    @movie = Movie.find(params[:id])
    @movie.destroy
    flash[:notice] = "Movie '#{@movie.title}' deleted."
    redirect_to movies_path
  end

  def search_tmdb
    set_config
    @title = params[:movie][:title]
    logger.debug @title
    @source = Tmdb::Search.new
    @source.resource('movie')
    @source.query(@title)
    @results = @source.fetch
    if @results.length > 0
      render "_choose_movie"
    else
      flash[:notice] = "Sorry, Not found for #{@title}"
      redirect_to movies_path
    end
  end

  def set_movie_from_result
    @movie = Movie.new( :title => params[:title], 
                        :rating => params[:rating], 
                        :release_date => params[:release_date], 
                        :description=> params[:description]) 
    @movie.save
    redirect_to movies_path
  end

  private

  def movie_params
    params.require(:movie).permit(:title, :rating, :release_date, :description)
  end

=begin
  def movies_with_good_reviews
    @movies = Movie.joins(:reviews).group(:movie_id).
      having('AVG(reviews.potatoes) > 3')
  end

  def movies_for_kids
    @movies = Movie.where('rating in ?', %w(G PG))
  end
  
  def movies_with_filters
    @movies = Movie.with_good_reviews(params[:threshold])
    @movies = @movies.for_kids          if params[:for_kids]
    @movies = @movies.with_many_fans    if params[:with_many_fans]
    @movies = @movies.recently_reviewed if params[:recently_reviewed]
  end
  # or even DRYer:
  def movies_with_filters_2
    @movies = Movie.with_good_reviews(params[:threshold])
    %w(for_kids with_many_fans recently_reviewed).each do |filter|
      @movies = @movies.send(filter) if params[filter]
  end
=end

end