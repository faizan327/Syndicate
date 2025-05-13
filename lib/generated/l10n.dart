// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name =
        (locale.countryCode?.isEmpty ?? false)
            ? locale.languageCode
            : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Admin`
  String get admin {
    return Intl.message('Admin', name: 'admin', desc: '', args: []);
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Logout`
  String get logout {
    return Intl.message('Logout', name: 'logout', desc: '', args: []);
  }

  /// `Todo List`
  String get todoList {
    return Intl.message('Todo List', name: 'todoList', desc: '', args: []);
  }

  /// `English`
  String get english {
    return Intl.message('English', name: 'english', desc: '', args: []);
  }

  /// `French`
  String get french {
    return Intl.message('French', name: 'french', desc: '', args: []);
  }

  /// `New Post`
  String get newPost {
    return Intl.message('New Post', name: 'newPost', desc: '', args: []);
  }

  /// `Next`
  String get next {
    return Intl.message('Next', name: 'next', desc: '', args: []);
  }

  /// `Recent`
  String get recent {
    return Intl.message('Recent', name: 'recent', desc: '', args: []);
  }

  /// `New Reels`
  String get newReels {
    return Intl.message('New Reels', name: 'newReels', desc: '', args: []);
  }

  /// `Post`
  String get post {
    return Intl.message('Post', name: 'post', desc: '', args: []);
  }

  /// `Reels`
  String get reels {
    return Intl.message('Reels', name: 'reels', desc: '', args: []);
  }

  /// `Share`
  String get share {
    return Intl.message('Share', name: 'share', desc: '', args: []);
  }

  /// `Write a caption...`
  String get writeACaption {
    return Intl.message(
      'Write a caption...',
      name: 'writeACaption',
      desc: '',
      args: [],
    );
  }

  /// `Add location`
  String get addLocation {
    return Intl.message(
      'Add location',
      name: 'addLocation',
      desc: '',
      args: [],
    );
  }

  /// `Please upload a profile image`
  String get pleaseUploadProfileImage {
    return Intl.message(
      'Please upload a profile image',
      name: 'pleaseUploadProfileImage',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get username {
    return Intl.message('Username', name: 'username', desc: '', args: []);
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Confirm Password`
  String get confirmPassword {
    return Intl.message(
      'Confirm Password',
      name: 'confirmPassword',
      desc: '',
      args: [],
    );
  }

  /// `Sign Up`
  String get signUp {
    return Intl.message('Sign Up', name: 'signUp', desc: '', args: []);
  }

  /// `Chats`
  String get chats {
    return Intl.message('Chats', name: 'chats', desc: '', args: []);
  }

  /// `No chats yet`
  String get noChatsYet {
    return Intl.message('No chats yet', name: 'noChatsYet', desc: '', args: []);
  }

  /// `Unknown User`
  String get unknownUser {
    return Intl.message(
      'Unknown User',
      name: 'unknownUser',
      desc: '',
      args: [],
    );
  }

  /// `Unable to load message`
  String get unableToLoadMessage {
    return Intl.message(
      'Unable to load message',
      name: 'unableToLoadMessage',
      desc: '',
      args: [],
    );
  }

  /// `No messages yet`
  String get noMessagesYet {
    return Intl.message(
      'No messages yet',
      name: 'noMessagesYet',
      desc: '',
      args: [],
    );
  }

  /// `Microphone permission denied`
  String get microphonePermissionDenied {
    return Intl.message(
      'Microphone permission denied',
      name: 'microphonePermissionDenied',
      desc: '',
      args: [],
    );
  }

  /// `Clear Chat`
  String get clearChat {
    return Intl.message('Clear Chat', name: 'clearChat', desc: '', args: []);
  }

  /// `Are you sure you want to clear this chat? This action cannot be undone.`
  String get areYouSureClearChat {
    return Intl.message(
      'Are you sure you want to clear this chat? This action cannot be undone.',
      name: 'areYouSureClearChat',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Clear`
  String get clear {
    return Intl.message('Clear', name: 'clear', desc: '', args: []);
  }

  /// `Chat cleared successfully.`
  String get chatClearedSuccessfully {
    return Intl.message(
      'Chat cleared successfully.',
      name: 'chatClearedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Syndicate user`
  String get syndicateUser {
    return Intl.message(
      'Syndicate user',
      name: 'syndicateUser',
      desc: '',
      args: [],
    );
  }

  /// `Replying to:`
  String get replyingTo {
    return Intl.message('Replying to:', name: 'replyingTo', desc: '', args: []);
  }

  /// `Failed to update profile`
  String get failedToUpdateProfile {
    return Intl.message(
      'Failed to update profile',
      name: 'failedToUpdateProfile',
      desc: '',
      args: [],
    );
  }

  /// `Username is already taken`
  String get usernameAlreadyTaken {
    return Intl.message(
      'Username is already taken',
      name: 'usernameAlreadyTaken',
      desc: '',
      args: [],
    );
  }

  /// `Edit Profile`
  String get editProfile {
    return Intl.message(
      'Edit Profile',
      name: 'editProfile',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a username`
  String get pleaseEnterUsername {
    return Intl.message(
      'Please enter a username',
      name: 'pleaseEnterUsername',
      desc: '',
      args: [],
    );
  }

  /// `Bio cannot be longer than 256 characters`
  String get bioTooLong {
    return Intl.message(
      'Bio cannot be longer than 256 characters',
      name: 'bioTooLong',
      desc: '',
      args: [],
    );
  }

  /// `Save Changes`
  String get saveChanges {
    return Intl.message(
      'Save Changes',
      name: 'saveChanges',
      desc: '',
      args: [],
    );
  }

  /// `Explore Screen`
  String get exploreScreen {
    return Intl.message(
      'Explore Screen',
      name: 'exploreScreen',
      desc: '',
      args: [],
    );
  }

  /// `Search User`
  String get searchUser {
    return Intl.message('Search User', name: 'searchUser', desc: '', args: []);
  }

  /// `Enter your email`
  String get enterYourEmail {
    return Intl.message(
      'Enter your email',
      name: 'enterYourEmail',
      desc: '',
      args: [],
    );
  }

  /// `Password reset email sent!`
  String get passwordResetEmailSent {
    return Intl.message(
      'Password reset email sent!',
      name: 'passwordResetEmailSent',
      desc: '',
      args: [],
    );
  }

  /// `Reset Password`
  String get resetPassword {
    return Intl.message(
      'Reset Password',
      name: 'resetPassword',
      desc: '',
      args: [],
    );
  }

  /// `Admin Access`
  String get adminAccess {
    return Intl.message(
      'Admin Access',
      name: 'adminAccess',
      desc: '',
      args: [],
    );
  }

  /// `Enter admin password`
  String get enterAdminPassword {
    return Intl.message(
      'Enter admin password',
      name: 'enterAdminPassword',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get submit {
    return Intl.message('Submit', name: 'submit', desc: '', args: []);
  }

  /// `Incorrect admin password.`
  String get incorrectAdminPassword {
    return Intl.message(
      'Incorrect admin password.',
      name: 'incorrectAdminPassword',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message('Email', name: 'email', desc: '', args: []);
  }

  /// `Sign Up as Admin`
  String get signUpAsAdmin {
    return Intl.message(
      'Sign Up as Admin',
      name: 'signUpAsAdmin',
      desc: '',
      args: [],
    );
  }

  /// `Forgot password?`
  String get forgotPassword {
    return Intl.message(
      'Forgot password?',
      name: 'forgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message('Login', name: 'login', desc: '', args: []);
  }

  /// `Don't have an account?`
  String get dontHaveAccount {
    return Intl.message(
      'Don\'t have an account?',
      name: 'dontHaveAccount',
      desc: '',
      args: [],
    );
  }

  /// `Notifications`
  String get notifications {
    return Intl.message(
      'Notifications',
      name: 'notifications',
      desc: '',
      args: [],
    );
  }

  /// `No notifications yet.`
  String get noNotificationsYet {
    return Intl.message(
      'No notifications yet.',
      name: 'noNotificationsYet',
      desc: '',
      args: [],
    );
  }

  /// `Profile`
  String get profile {
    return Intl.message('Profile', name: 'profile', desc: '', args: []);
  }

  /// `Save draft`
  String get saveDraft {
    return Intl.message('Save draft', name: 'saveDraft', desc: '', args: []);
  }

  /// `Send`
  String get send {
    return Intl.message('Send', name: 'send', desc: '', args: []);
  }

  /// `Already have an account?`
  String get alreadyHaveAnAccount {
    return Intl.message(
      'Already have an account?',
      name: 'alreadyHaveAnAccount',
      desc: '',
      args: [],
    );
  }

  /// `No items selected`
  String get noItemsSelected {
    return Intl.message(
      'No items selected',
      name: 'noItemsSelected',
      desc: '',
      args: [],
    );
  }

  /// `Add to Story`
  String get addToStory {
    return Intl.message('Add to Story', name: 'addToStory', desc: '', args: []);
  }

  /// `Photos`
  String get photos {
    return Intl.message('Photos', name: 'photos', desc: '', args: []);
  }

  /// `Videos`
  String get videos {
    return Intl.message('Videos', name: 'videos', desc: '', args: []);
  }

  /// `Camera`
  String get camera {
    return Intl.message('Camera', name: 'camera', desc: '', args: []);
  }

  /// `Select`
  String get select {
    return Intl.message('Select', name: 'select', desc: '', args: []);
  }

  /// `No media found`
  String get noMediaFound {
    return Intl.message(
      'No media found',
      name: 'noMediaFound',
      desc: '',
      args: [],
    );
  }

  /// `Viewers of this story`
  String get viewersOfThisStory {
    return Intl.message(
      'Viewers of this story',
      name: 'viewersOfThisStory',
      desc: '',
      args: [],
    );
  }

  /// `No user logged in!`
  String get noUserLoggedIn {
    return Intl.message(
      'No user logged in!',
      name: 'noUserLoggedIn',
      desc: '',
      args: [],
    );
  }

  /// `Story uploaded successfully`
  String get storyUploadedSuccessfully {
    return Intl.message(
      'Story uploaded successfully',
      name: 'storyUploadedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `All stories uploaded successfully`
  String get allStoriesUploadedSuccessfully {
    return Intl.message(
      'All stories uploaded successfully',
      name: 'allStoriesUploadedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Error uploading story`
  String get errorUploadingStory {
    return Intl.message(
      'Error uploading story',
      name: 'errorUploadingStory',
      desc: '',
      args: [],
    );
  }

  /// `No media to preview`
  String get noMediaToPreview {
    return Intl.message(
      'No media to preview',
      name: 'noMediaToPreview',
      desc: '',
      args: [],
    );
  }

  /// `Uploading...`
  String get uploading {
    return Intl.message('Uploading...', name: 'uploading', desc: '', args: []);
  }

  /// `Upload Story`
  String get uploadStory {
    return Intl.message(
      'Upload Story',
      name: 'uploadStory',
      desc: '',
      args: [],
    );
  }

  /// `Upload All`
  String get uploadAll {
    return Intl.message('Upload All', name: 'uploadAll', desc: '', args: []);
  }

  /// `Could not load image`
  String get couldNotLoadImage {
    return Intl.message(
      'Could not load image',
      name: 'couldNotLoadImage',
      desc: '',
      args: [],
    );
  }

  /// `Add a comment`
  String get addAComment {
    return Intl.message(
      'Add a comment',
      name: 'addAComment',
      desc: '',
      args: [],
    );
  }

  /// `Posts`
  String get posts {
    return Intl.message('Posts', name: 'posts', desc: '', args: []);
  }

  /// `Followers`
  String get followers {
    return Intl.message('Followers', name: 'followers', desc: '', args: []);
  }

  /// `Following`
  String get following {
    return Intl.message('Following', name: 'following', desc: '', args: []);
  }

  /// `Unfollow`
  String get unfollow {
    return Intl.message('Unfollow', name: 'unfollow', desc: '', args: []);
  }

  /// `Follow`
  String get follow {
    return Intl.message('Follow', name: 'follow', desc: '', args: []);
  }

  /// `Edit Your Profile`
  String get editYourProfile {
    return Intl.message(
      'Edit Your Profile',
      name: 'editYourProfile',
      desc: '',
      args: [],
    );
  }

  /// `Message`
  String get message {
    return Intl.message('Message', name: 'message', desc: '', args: []);
  }

  /// `All`
  String get all {
    return Intl.message('All', name: 'all', desc: '', args: []);
  }

  /// `Hello`
  String get hello {
    return Intl.message('Hello', name: 'hello', desc: '', args: []);
  }

  /// `Task Manager`
  String get taskManager {
    return Intl.message(
      'Task Manager',
      name: 'taskManager',
      desc: '',
      args: [],
    );
  }

  /// `New Task`
  String get newTask {
    return Intl.message('New Task', name: 'newTask', desc: '', args: []);
  }

  /// `No tasks yet`
  String get noTasksYet {
    return Intl.message('No tasks yet', name: 'noTasksYet', desc: '', args: []);
  }

  /// `Loading...`
  String get loading {
    return Intl.message('Loading...', name: 'loading', desc: '', args: []);
  }

  /// `Error`
  String get error {
    return Intl.message('Error', name: 'error', desc: '', args: []);
  }

  /// `Completed`
  String get completed {
    return Intl.message('Completed', name: 'completed', desc: '', args: []);
  }

  /// `Pending`
  String get pending {
    return Intl.message('Pending', name: 'pending', desc: '', args: []);
  }

  /// `High`
  String get high {
    return Intl.message('High', name: 'high', desc: '', args: []);
  }

  /// `Medium`
  String get medium {
    return Intl.message('Medium', name: 'medium', desc: '', args: []);
  }

  /// `Low`
  String get low {
    return Intl.message('Low', name: 'low', desc: '', args: []);
  }

  /// `Add New Task`
  String get addNewTask {
    return Intl.message('Add New Task', name: 'addNewTask', desc: '', args: []);
  }

  /// `Task`
  String get task {
    return Intl.message('Task', name: 'task', desc: '', args: []);
  }

  /// `Description`
  String get description {
    return Intl.message('Description', name: 'description', desc: '', args: []);
  }

  /// `Priority`
  String get priority {
    return Intl.message('Priority', name: 'priority', desc: '', args: []);
  }

  /// `Pick Due Date`
  String get pickDueDate {
    return Intl.message(
      'Pick Due Date',
      name: 'pickDueDate',
      desc: '',
      args: [],
    );
  }

  /// `Due Date`
  String get dueDate {
    return Intl.message('Due Date', name: 'dueDate', desc: '', args: []);
  }

  /// `Select Category`
  String get selectCategory {
    return Intl.message(
      'Select Category',
      name: 'selectCategory',
      desc: '',
      args: [],
    );
  }

  /// `Add New Category`
  String get addNewCategory {
    return Intl.message(
      'Add New Category',
      name: 'addNewCategory',
      desc: '',
      args: [],
    );
  }

  /// `Enter Category`
  String get enterCategory {
    return Intl.message(
      'Enter Category',
      name: 'enterCategory',
      desc: '',
      args: [],
    );
  }

  /// `Add Category`
  String get addCategory {
    return Intl.message(
      'Add Category',
      name: 'addCategory',
      desc: '',
      args: [],
    );
  }

  /// `Chapters`
  String get chapters {
    return Intl.message('Chapters', name: 'chapters', desc: '', args: []);
  }

  /// `No Categories Found`
  String get noCategoriesFound {
    return Intl.message(
      'No Categories Found',
      name: 'noCategoriesFound',
      desc: '',
      args: [],
    );
  }

  /// `Let's learn`
  String get letsLearn {
    return Intl.message('Let\'s learn', name: 'letsLearn', desc: '', args: []);
  }

  /// `Something new`
  String get somethingNew {
    return Intl.message(
      'Something new',
      name: 'somethingNew',
      desc: '',
      args: [],
    );
  }

  /// `Saved Posts`
  String get savedPosts {
    return Intl.message('Saved Posts', name: 'savedPosts', desc: '', args: []);
  }

  /// `Bio`
  String get bio {
    return Intl.message('Bio', name: 'bio', desc: '', args: []);
  }

  /// `Change Photo`
  String get changephoto {
    return Intl.message(
      'Change Photo',
      name: 'changephoto',
      desc: '',
      args: [],
    );
  }

  /// `Mark All as Read`
  String get markAllAsRead {
    return Intl.message(
      'Mark All as Read',
      name: 'markAllAsRead',
      desc: '',
      args: [],
    );
  }

  /// `Clear Notifications`
  String get clearNotifications {
    return Intl.message(
      'Clear Notifications',
      name: 'clearNotifications',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: '', args: []);
  }

  /// `Report`
  String get report {
    return Intl.message('Report', name: 'report', desc: '', args: []);
  }

  /// `Spam`
  String get spam {
    return Intl.message('Spam', name: 'spam', desc: '', args: []);
  }

  /// `Sexual Content`
  String get sexualContent {
    return Intl.message(
      'Sexual Content',
      name: 'sexualContent',
      desc: '',
      args: [],
    );
  }

  /// `Violence`
  String get violence {
    return Intl.message('Violence', name: 'violence', desc: '', args: []);
  }

  /// `Harassment`
  String get harassment {
    return Intl.message('Harassment', name: 'harassment', desc: '', args: []);
  }

  /// `Other`
  String get other {
    return Intl.message('Other', name: 'other', desc: '', args: []);
  }

  /// `No reported posts found`
  String get noReportedPostsFound {
    return Intl.message(
      'No reported posts found',
      name: 'noReportedPostsFound',
      desc: '',
      args: [],
    );
  }

  /// `Filter by reason`
  String get filterByReason {
    return Intl.message(
      'Filter by reason',
      name: 'filterByReason',
      desc: '',
      args: [],
    );
  }

  /// `Reported by`
  String get reportedBy {
    return Intl.message('Reported by', name: 'reportedBy', desc: '', args: []);
  }

  /// `Reported on`
  String get reportedOn {
    return Intl.message('Reported on', name: 'reportedOn', desc: '', args: []);
  }

  /// `Reason`
  String get reason {
    return Intl.message('Reason', name: 'reason', desc: '', args: []);
  }

  /// `Delete post? Once deleted, This cannot be undo.`
  String get deletePostConfirmation {
    return Intl.message(
      'Delete post? Once deleted, This cannot be undo.',
      name: 'deletePostConfirmation',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Deletion`
  String get confirmDeletion {
    return Intl.message(
      'Confirm Deletion',
      name: 'confirmDeletion',
      desc: '',
      args: [],
    );
  }

  /// `Category`
  String get category {
    return Intl.message('Category', name: 'category', desc: '', args: []);
  }

  /// `Edit Category`
  String get editCategory {
    return Intl.message(
      'Edit Category',
      name: 'editCategory',
      desc: '',
      args: [],
    );
  }

  /// `Enter New Category Name`
  String get enterNewCategoryName {
    return Intl.message(
      'Enter New Category Name',
      name: 'enterNewCategoryName',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get edit {
    return Intl.message('Edit', name: 'edit', desc: '', args: []);
  }

  /// `Light Theme`
  String get lightTheme {
    return Intl.message('Light Theme', name: 'lightTheme', desc: '', args: []);
  }

  /// `Dark Theme`
  String get darkTheme {
    return Intl.message('Dark Theme', name: 'darkTheme', desc: '', args: []);
  }

  /// `System Default`
  String get systemDefault {
    return Intl.message(
      'System Default',
      name: 'systemDefault',
      desc: '',
      args: [],
    );
  }

  /// `Create Account`
  String get createAccount {
    return Intl.message(
      'Create Account',
      name: 'createAccount',
      desc: '',
      args: [],
    );
  }

  /// `Sign up to get started`
  String get signUpToGetStarted {
    return Intl.message(
      'Sign up to get started',
      name: 'signUpToGetStarted',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your email`
  String get pleaseEnterEmail {
    return Intl.message(
      'Please enter your email',
      name: 'pleaseEnterEmail',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid email`
  String get enterValidEmail {
    return Intl.message(
      'Enter a valid email',
      name: 'enterValidEmail',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a password`
  String get pleaseEnterPassword {
    return Intl.message(
      'Please enter a password',
      name: 'pleaseEnterPassword',
      desc: '',
      args: [],
    );
  }

  /// `Password must be at least 6 characters`
  String get passwordTooShort {
    return Intl.message(
      'Password must be at least 6 characters',
      name: 'passwordTooShort',
      desc: '',
      args: [],
    );
  }

  /// `Please confirm your password`
  String get pleaseConfirmPassword {
    return Intl.message(
      'Please confirm your password',
      name: 'pleaseConfirmPassword',
      desc: '',
      args: [],
    );
  }

  /// `Passwords do not match`
  String get passwordsDontMatch {
    return Intl.message(
      'Passwords do not match',
      name: 'passwordsDontMatch',
      desc: '',
      args: [],
    );
  }

  /// `3-30 characters (letters, numbers, . or _)`
  String get usernameRules {
    return Intl.message(
      '3-30 characters (letters, numbers, . or _)',
      name: 'usernameRules',
      desc: '',
      args: [],
    );
  }

  /// `This username is taken`
  String get usernameTaken {
    return Intl.message(
      'This username is taken',
      name: 'usernameTaken',
      desc: '',
      args: [],
    );
  }

  /// `Edit Event`
  String get editEvent {
    return Intl.message('Edit Event', name: 'editEvent', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Upcoming Events`
  String get upcomingEvents {
    return Intl.message(
      'Upcoming Events',
      name: 'upcomingEvents',
      desc: '',
      args: [],
    );
  }

  /// `Delete Event`
  String get deleteEvent {
    return Intl.message(
      'Delete Event',
      name: 'deleteEvent',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this event?`
  String get areYouSureDeleteEvent {
    return Intl.message(
      'Are you sure you want to delete this event?',
      name: 'areYouSureDeleteEvent',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `Saved Posts`
  String get savedPost {
    return Intl.message('Saved Posts', name: 'savedPost', desc: '', args: []);
  }

  /// `Theme`
  String get theme {
    return Intl.message('Theme', name: 'theme', desc: '', args: []);
  }

  /// `No users found.`
  String get noUsersFound {
    return Intl.message(
      'No users found.',
      name: 'noUsersFound',
      desc: '',
      args: [],
    );
  }

  /// `Clipboard not supported on this platform.`
  String get clipboardNotSupported {
    return Intl.message(
      'Clipboard not supported on this platform.',
      name: 'clipboardNotSupported',
      desc: '',
      args: [],
    );
  }

  /// `Messages copied to clipboard`
  String get messagesCopied {
    return Intl.message(
      'Messages copied to clipboard',
      name: 'messagesCopied',
      desc: '',
      args: [],
    );
  }

  /// `No text messages selected to copy`
  String get noTextMessagesToCopy {
    return Intl.message(
      'No text messages selected to copy',
      name: 'noTextMessagesToCopy',
      desc: '',
      args: [],
    );
  }

  /// `Choose an option for the selected messages:`
  String get chooseOptionForMessages {
    return Intl.message(
      'Choose an option for the selected messages:',
      name: 'chooseOptionForMessages',
      desc: '',
      args: [],
    );
  }

  /// `Delete Messages`
  String get deleteMessages {
    return Intl.message(
      'Delete Messages',
      name: 'deleteMessages',
      desc: '',
      args: [],
    );
  }

  /// `Delete for Me`
  String get deleteForMe {
    return Intl.message(
      'Delete for Me',
      name: 'deleteForMe',
      desc: '',
      args: [],
    );
  }

  /// `Delete for Everyone`
  String get deleteForEveryone {
    return Intl.message(
      'Delete for Everyone',
      name: 'deleteForEveryone',
      desc: '',
      args: [],
    );
  }

  /// `Copy selected messages`
  String get copySelectedMessages {
    return Intl.message(
      'Copy selected messages',
      name: 'copySelectedMessages',
      desc: '',
      args: [],
    );
  }

  /// `Forward selected messages`
  String get forwardSelectedMessages {
    return Intl.message(
      'Forward selected messages',
      name: 'forwardSelectedMessages',
      desc: '',
      args: [],
    );
  }

  /// `Proceed`
  String get proceed {
    return Intl.message('Proceed', name: 'proceed', desc: '', args: []);
  }

  /// `This category contains`
  String get categorycontains {
    return Intl.message(
      'This category contains',
      name: 'categorycontains',
      desc: '',
      args: [],
    );
  }

  /// `video(s). Please select a new category to move them to:`
  String get selectcategory {
    return Intl.message(
      'video(s). Please select a new category to move them to:',
      name: 'selectcategory',
      desc: '',
      args: [],
    );
  }

  /// `New Category`
  String get newcategory {
    return Intl.message(
      'New Category',
      name: 'newcategory',
      desc: '',
      args: [],
    );
  }

  /// `Please Select New Category`
  String get selectnewcategory {
    return Intl.message(
      'Please Select New Category',
      name: 'selectnewcategory',
      desc: '',
      args: [],
    );
  }

  /// `Error loading data:`
  String get errorloadingdata {
    return Intl.message(
      'Error loading data:',
      name: 'errorloadingdata',
      desc: '',
      args: [],
    );
  }

  /// `Name Your PDF`
  String get namepdf {
    return Intl.message('Name Your PDF', name: 'namepdf', desc: '', args: []);
  }

  /// `PDF Title`
  String get pdftitle {
    return Intl.message('PDF Title', name: 'pdftitle', desc: '', args: []);
  }

  /// `Please Enter Title`
  String get entertitle {
    return Intl.message(
      'Please Enter Title',
      name: 'entertitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter a descriptive title`
  String get descriptivetitle {
    return Intl.message(
      'Enter a descriptive title',
      name: 'descriptivetitle',
      desc: '',
      args: [],
    );
  }

  /// `Error fetching data:`
  String get errorFetchingData {
    return Intl.message(
      'Error fetching data:',
      name: 'errorFetchingData',
      desc: '',
      args: [],
    );
  }

  /// `Upload failed:`
  String get uploadFailed {
    return Intl.message(
      'Upload failed:',
      name: 'uploadFailed',
      desc: '',
      args: [],
    );
  }

  /// `Error during upload process:`
  String get errorDuringUpload {
    return Intl.message(
      'Error during upload process:',
      name: 'errorDuringUpload',
      desc: '',
      args: [],
    );
  }

  /// `Could not launch PDF download`
  String get couldNotLaunchPdfDownload {
    return Intl.message(
      'Could not launch PDF download',
      name: 'couldNotLaunchPdfDownload',
      desc: '',
      args: [],
    );
  }

  /// `Failed to edit PDF:`
  String get failedToEditPdf {
    return Intl.message(
      'Failed to edit PDF:',
      name: 'failedToEditPdf',
      desc: '',
      args: [],
    );
  }

  /// `Failed to delete PDF:`
  String get failedToDeletePdf {
    return Intl.message(
      'Failed to delete PDF:',
      name: 'failedToDeletePdf',
      desc: '',
      args: [],
    );
  }

  /// `Failed to edit subcategory:`
  String get failedToEditSubcategory {
    return Intl.message(
      'Failed to edit subcategory:',
      name: 'failedToEditSubcategory',
      desc: '',
      args: [],
    );
  }

  /// `Failed to delete subcategory:`
  String get failedToDeleteSubcategory {
    return Intl.message(
      'Failed to delete subcategory:',
      name: 'failedToDeleteSubcategory',
      desc: '',
      args: [],
    );
  }

  /// `PDFs`
  String get pdfs {
    return Intl.message('PDFs', name: 'pdfs', desc: '', args: []);
  }

  /// `Subcategories`
  String get subcategories {
    return Intl.message(
      'Subcategories',
      name: 'subcategories',
      desc: '',
      args: [],
    );
  }

  /// `Subcategory Name`
  String get subcategoryname {
    return Intl.message(
      'Subcategory Name',
      name: 'subcategoryname',
      desc: '',
      args: [],
    );
  }

  /// `No videos available.`
  String get noVideosAvailable {
    return Intl.message(
      'No videos available.',
      name: 'noVideosAvailable',
      desc: '',
      args: [],
    );
  }

  /// `No PDFs available.`
  String get noPdfsAvailable {
    return Intl.message(
      'No PDFs available.',
      name: 'noPdfsAvailable',
      desc: '',
      args: [],
    );
  }

  /// `No subcategories available.`
  String get noSubcategoriesAvailable {
    return Intl.message(
      'No subcategories available.',
      name: 'noSubcategoriesAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Add Content`
  String get addContent {
    return Intl.message('Add Content', name: 'addContent', desc: '', args: []);
  }

  /// `Upload PDF`
  String get uploadPdf {
    return Intl.message('Upload PDF', name: 'uploadPdf', desc: '', args: []);
  }

  /// `Upload Reel`
  String get uploadReel {
    return Intl.message('Upload Reel', name: 'uploadReel', desc: '', args: []);
  }

  /// `Add Subcategory`
  String get addSubcategory {
    return Intl.message(
      'Add Subcategory',
      name: 'addSubcategory',
      desc: '',
      args: [],
    );
  }

  /// `Edit PDF`
  String get editPdf {
    return Intl.message('Edit PDF', name: 'editPdf', desc: '', args: []);
  }

  /// `Delete PDF`
  String get deletePdf {
    return Intl.message('Delete PDF', name: 'deletePdf', desc: '', args: []);
  }

  /// `Edit Subcategory`
  String get editSubcategory {
    return Intl.message(
      'Edit Subcategory',
      name: 'editSubcategory',
      desc: '',
      args: [],
    );
  }

  /// `Delete Subcategory`
  String get deleteSubcategory {
    return Intl.message(
      'Delete Subcategory',
      name: 'deleteSubcategory',
      desc: '',
      args: [],
    );
  }

  /// `Uploaded Successfully!`
  String get pdfUploadedSuccessfully {
    return Intl.message(
      'Uploaded Successfully!',
      name: 'pdfUploadedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get deletePdfConfirmation {
    return Intl.message(
      'Delete',
      name: 'deletePdfConfirmation',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this PDF?`
  String get areYouSureDeletePdf {
    return Intl.message(
      'Are you sure you want to delete this PDF?',
      name: 'areYouSureDeletePdf',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get deleteSubcategoryConfirmation {
    return Intl.message(
      'Delete',
      name: 'deleteSubcategoryConfirmation',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this subcategory?`
  String get areYouSureDeleteSubcategory {
    return Intl.message(
      'Are you sure you want to delete this subcategory?',
      name: 'areYouSureDeleteSubcategory',
      desc: '',
      args: [],
    );
  }

  /// `Tap to watch`
  String get tapToWatch {
    return Intl.message('Tap to watch', name: 'tapToWatch', desc: '', args: []);
  }

  /// `Tap to view PDF`
  String get tapToViewPdf {
    return Intl.message(
      'Tap to view PDF',
      name: 'tapToViewPdf',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this category?`
  String get deletecategory {
    return Intl.message(
      'Are you sure you want to delete this category?',
      name: 'deletecategory',
      desc: '',
      args: [],
    );
  }

  /// `PDF Viewer`
  String get pdfViewerTitle {
    return Intl.message(
      'PDF Viewer',
      name: 'pdfViewerTitle',
      desc: '',
      args: [],
    );
  }

  /// `Reload PDF`
  String get reloadPdf {
    return Intl.message('Reload PDF', name: 'reloadPdf', desc: '', args: []);
  }

  /// `Error loading PDF`
  String get errorLoadingPdf {
    return Intl.message(
      'Error loading PDF',
      name: 'errorLoadingPdf',
      desc: '',
      args: [],
    );
  }

  /// `Error rendering PDF`
  String get errorRenderingPdf {
    return Intl.message(
      'Error rendering PDF',
      name: 'errorRenderingPdf',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load PDF`
  String get failedToLoadPdf {
    return Intl.message(
      'Failed to load PDF',
      name: 'failedToLoadPdf',
      desc: '',
      args: [],
    );
  }

  /// `First Page`
  String get firstPage {
    return Intl.message('First Page', name: 'firstPage', desc: '', args: []);
  }

  /// `Previous Page`
  String get previousPage {
    return Intl.message(
      'Previous Page',
      name: 'previousPage',
      desc: '',
      args: [],
    );
  }

  /// `Next Page`
  String get nextPage {
    return Intl.message('Next Page', name: 'nextPage', desc: '', args: []);
  }

  /// `Last Page`
  String get lastPage {
    return Intl.message('Last Page', name: 'lastPage', desc: '', args: []);
  }

  /// `Page `
  String get pageInfo {
    return Intl.message('Page ', name: 'pageInfo', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'fr'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
