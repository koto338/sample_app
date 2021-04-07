require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # setupメソッド内に書かれた処理は、各テストが走る直前に実行されます
  def setup
    @user = User.new(name: "Example User",email: "user@example.com",
                    # パスワードとパスワード確認の値を追加
                    password: "foobar", password_confirmation: "foobar")
  end
  
  # valid?メソッドを使ってUserオブジェクトの有効性をテストする
  # $ rails test:models モデルに関するテストだけを走らせるコマンド
  test "should be valid" do
    assert @user.valid?
  end
  
  # @user変数のname属性に対して空白の文字列をセット
  # assert_notメソッドを使って Userオブジェクトが有効でなくなったことを確認します。
  # $ rails test:models
  test "name should be present" do
    @user.name =""
    assert_not @user.valid?
  end
  
  # email属性の存在性のテスト
  test "email should be present" do
    @user.email = "  "
    assert_not @user.valid?
  end
  
  # nameの長さの検証に対するテスト
  test "name should not be too long" do 
    @user.name = "a" * 51
    assert_not @user.valid?
  end
  
  test "email should not be too long" do
    @user.email = "a" * 244 + "@example.com"
    assert_not @user.valid?
  end
  
  # 有効なメールフォーマットをテストする
  test "email validation should accept valid addresses" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
                         first.last@foo.jp alice+bob@baz.cn]
    valid_addresses.each do |valid_address|
      @user.email = valid_address
      # どのメールアドレスでテストが失敗したのかを特定できるようになります
      # 詳細な文字列を調べるために　inspectメソッドを使っています
      assert @user.valid?, "#{valid_address.inspect} should be valid"
    end
  end
  
  # 無効なメールアドレスを使って 「無効性 (Invalidity)」についてテスト
  test "email validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                           foo@bar_baz.com foo@bar+baz.com]
    invalid_addresses.each do |invalid_address|
      @user.email = invalid_address
      assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"
    end
  end
  
  # 重複するメールアドレス拒否のテスト 
  # @userと同じメールアドレスのユーザーは作成できないことを、@user.dupを使ってテストしています。
  # dupは、同じ属性を持つデータを複製するためのメソッドです。
  test "email addresses should be unique" do
    duplicate_user = @user.dup
    # 大文字小文字を区別しない、一意性のテスト
    duplicate_user.email = @user.email.upcase
    @user.save
    assert_not duplicate_user.valid?
  end
  
  test "password should be present (nonblank)" do
    @user.password = @user.password_confirmation = " " * 6
    assert_not @user.valid?
  end
  
  test "password should have a minimum length" do
    # passwordとpassword_confirmationに対して同時に代入
    @user.password = @user.password_confirmation = "a" * 5
    assert_not @user.valid?
  end
  
  test "authenticated? should return false for a user with nil digest" do
    assert_not @user.authenticated?(:remember, '')
  end
  
  test "associated microposts should be destyoyed" do
    @user.save
    @user.microposts.create!(content: "Lorem ipsum")
    assert_difference 'Micropost.count', -1 do
      @user.destroy
    end
  end
  
  test "should follow and unfollow a user" do
    michael = users(:michael)
    archer = users(:archer)
    assert_not michael.following?(archer)
    michael.follow(archer)
    assert michael.following?(archer)
    assert archer.followers.include?(michael)
    michael.unfollow(archer)
    assert_not michael.following?(archer)
  end
  
  test "feed should have the reight posts" do
    michael = users(:michael)
    archer  = users(:archer)
    lana    = users(:lana)
    # フォローしているユーザーの投稿を確認
    lana.microposts.each do |post_following|
      assert michael.feed.include?(post_following)
    end
    # 自分自身の投稿を確認
    michael.microposts.each do |post_self|
      assert michael.feed.include?(post_self)
    end
    # フォローしていないユーザーの投稿を確認
    archer.microposts.each do |post_unfollowed|
      assert_not michael.feed.include?(post_unfollowed)
    end
  end
end
