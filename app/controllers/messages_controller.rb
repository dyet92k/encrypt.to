class MessagesController < ApplicationController

  # GET /messages/new
  def new
    @message = Message.new
    
    @to = params[:email]
    IO.popen ("curl '#{APP_CONFIG['keyserver']}/pks/lookup?op=get&search=#{@to}&options=mr'") { |f| @pubkey = f.read }
    
    respond_to do |format|
      if @pubkey.include?("BEGIN PGP PUBLIC KEY BLOCK") and (is_email?(@to) or @to.include?("0x"))
        format.html
      else
        format.html { redirect_to "/" }
      end  
    end
  end

  # POST /messages
  def create
    @message = Message.new(params[:message])

    if !is_email?(@message.to)
      IO.popen ("curl '#{APP_CONFIG['keyserver']}/pks/lookup?op=vindex&search=#{params[:message][:to]}&fingerprint=on&options=mr'") { |f| @result = f.read }
      @message.to = get_email(@result)
      @message.save 
    end
    
    respond_to do |format|
      if @message.save
        MessageMailer.send_message(@message).deliver
        MessageMailer.thanks_message(@message).deliver
        format.html { redirect_to "/", notice: 'Encrypted message sent! Thanks.' }
      else
        format.html { redirect_to "/", notice: 'Sorry something went wrong. Try again!' }
      end
    end
  end

end
