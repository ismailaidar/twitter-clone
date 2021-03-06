class TweetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tweet, only: [:show, :edit, :update, :destroy]
  protect_from_forgery prepend: true

  include CableReady::Broadcaster


  # GET /tweets
  # GET /tweets.json
  def index
    @tweets = Tweet.order(created_at: :desc)
    @tweet = Tweet.new
    @like = Like.new
  end

  def my_tweets
    @tweets = current_user.tweets.order(created_at: :desc)
    @tweet = Tweet.new
    @like = Like.new
  end

  def like_tweet
    tweet = Tweet.find(params[:like][:tweet_id])
    @like = Like.new(like_params)
    @like.tweet = tweet
    @like.user = current_user
    @like.save
    cable_ready["timeline-stream"].text_content(
      selector: "#likes-#{tweet.id}", #string containing a CSS selector or XPath expression
      text: Like.where(tweet: tweet).count
    )
    cable_ready.broadcast
    redirect_to index
  end
  


  # GET /tweets/1
  # GET /tweets/1.json
  def show
  end

  # GET /tweets/new
  def new
    @tweet = Tweet.new
  end

  # GET /tweets/1/edit
  def edit
  end

  # POST /tweets
  # POST /tweets.json
  def create
    @tweet = Tweet.new(tweet_params)
    @tweet.user = current_user

    
    respond_to do |format|
      if @tweet.save
        cable_ready["timeline-stream"].insert_adjacent_html(
          selector: "#timeline", #string containing a CSS selector or XPath expression
          position: "afterbegin",
          html: render_to_string(partial: 'tweet', locals: {tweet: @tweet})
        )
        cable_ready.broadcast
        format.html { redirect_to index, notice: 'Tweet was successfully created.' }
      else
        format.html { redirect_to index, notice: 'Tweet was NOT created.' }
      end
    end
  end

  # PATCH/PUT /tweets/1
  # PATCH/PUT /tweets/1.json
  def update
    respond_to do |format|
      if @tweet.update(tweet_params)
        format.html { redirect_to @tweet, notice: 'Tweet was successfully updated.' }
        format.json { render :show, status: :ok, location: @tweet }
      else
        format.html { render :edit }
        format.json { render json: @tweet.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tweets/1
  # DELETE /tweets/1.json
  def destroy
    @tweet.destroy
    respond_to do |format|
      format.html { redirect_to tweets_url, notice: 'Tweet was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tweet
      @tweet = Tweet.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tweet_params
      params.require(:tweet).permit(:body)
    end

    def like_params
      params.require(:like).permit(:tweet_id)
    end
end
