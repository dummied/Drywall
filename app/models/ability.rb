class Ability
  include CanCan::Ability

  def initialize(user)
    if user && user.admin?
      can :manage, :all
    elsif user && user.author?
      can [:create, :edit], Thing do |thing|
        thing && thing.user == user
      end
      can [:create, :edit, :destroy], List do |list|
        list && list.user == user
      end
    else
      can :read, :all do |object_class, object|
        object_class != Setting
      end
    end
  end
end