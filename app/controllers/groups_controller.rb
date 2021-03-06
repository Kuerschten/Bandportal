class GroupsController < ApplicationController

  def add_user
    @group = Group.find(params[:id])

    u = User.find(params[:user_id])

    u.groups << @group

    if defined?(params[:instr_id]) && (not params[:instr_id].nil?)
      m = Membership.where "group_id = #{@group.id}
                              AND userable_id = #{u.id}
                              AND userable_type = 'User'"
      params[:instr_id].each do |i|
        m.first.instruments << Instrument.find(i)
      end
    end

    redirect_to @group
  end

  def add_unreg_user
    @group = Group.find(params[:id])

    u = UnregisteredUser.new
    u.prename = params[:unreg_prename]
    u.name = params[:unreg_surname]
    u.save

    u.groups << @group

    if defined?(params[:instr_id]) && (not params[:instr_id].nil?)
      m = Membership.where "group_id = #{@group.id}
                              AND userable_id = #{u.id}
                              AND userable_type = 'UnregisteredUser'"
      params[:instr_id].each do |i|
        m.first.instruments << Instrument.find(i)
      end
    end

    redirect_to @group
  end

  def remove_user
    @group = Group.find(params[:id])

    Membership.where("group_id = #{params[:id]}
                      AND userable_id = #{params[:user_id]}
                      AND userable_type = '#{params[:user_type]}'").first.destroy

    if params[:user_type] == "UnregisteredUser"
      UnregisteredUser.find(params[:user_id]).destroy
    end

    users = Membership.where ("group_id = #{params[:id]}
                      AND userable_type = 'User'")

    unless users.empty?
      redirect_to @group
    else
      @group.destroy
      redirect_to root_path
    end
  end

  # GET /groups
  # GET /groups.json
  def index
    @groups = Group.all

    @host_groups    = Group.where "groupable_type = 'HostGroup'"
    @fan_groups     = Group.where "groupable_type = 'FanGroup'"
    @artist_groups  = Group.where "groupable_type = 'ArtistGroup'"

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
    @group      = Group.find(params[:id])
    @is_artist  = false
    @is_host    = false

    if (@group.groupable_type == 'ArtistGroup')
      @show_class = 'Kuenstlergruppe'
      @all_instruments = Instrument.all
      @is_artist = true
    elsif (@group.groupable_type == 'FanGroup')
      fg = Group.where "groupable_type = 'ArtistGroup'
                    AND groupable_id   = ?", FanGroup.find(@group.groupable_id).artist_group_id
      if fg.empty?
        @show_class = "Fangruppe (die zugehoerige Band ist nicht mehr aktiv)"
      else
        @show_class = "#{fg.first.name} - Fangruppe"
      end
    elsif (@group.groupable_type == 'HostGroup')
      @show_class = 'Veranstaltergruppe'
      @hg = HostGroup.find @group.groupable_id
      @is_host = true
    else
      @show_class = 'untypisierte Gruppe'
    end

    @all_registered_users = (User.all - @group.members)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.json
  def new
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find(params[:id])
  end

  def selecttype
    @group_type = params[:group_type]

    if @group_type.to_i == 1
      @all_instruments = Instrument.all
    elsif @group_type.to_i == 2
      @art_groups = Group.where "groupable_type = 'ArtistGroup'"
    end

    @group = Group.new(params[:group])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @group }
    end
  end

  # POST /groups
  # POST /groups.json
  def create
    cu = User.find params[:user_id]

    @group = Group.new(params[:group])
    cu.groups << @group

    case params[:group_type].to_i
      when 1
        @group.groupable = ArtistGroup.create

        if defined?(params[:instr_id]) && (not params[:instr_id].nil?)
          m = Membership.where "group_id = #{@group.id}
                                  AND userable_id = #{cu.id}
                                  AND userable_type = 'User'"
          params[:instr_id].each do |i|
            m.first.instruments << Instrument.find(i)
          end
        end
      when 2
        @group.groupable = FanGroup.create :artist_group => ArtistGroup.find(params[:art_group_id].to_i)
      when 3
        @group.groupable = HostGroup.create
    end



    respond_to do |format|
      if @group.save
        format.html { redirect_to @group, notice: 'Die Gruppe wurde erfolgreich angelegt.' }
        format.json { render json: @group, status: :created, location: @group }
      else
        format.html { render action: "new" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
    @group = Group.find(params[:id])

    respond_to do |format|
      if @group.update_attributes(params[:group])
        format.html { redirect_to @group, notice: 'Group was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group = Group.find(params[:id])

    mbs = Membership.where "group_id = ?", @group.id

    mbs.each do |m|
      m.destroy
    end

    @group.destroy

    respond_to do |format|
      format.html { redirect_to groups_url }
      format.json { head :ok }
    end
  end
end
