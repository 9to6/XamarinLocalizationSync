# XamarinLocalizationSync

When you use Xamarin.Forms, this code help u for synchronization of localization file .

If you have a ruby development environment, you can download this files and execute it directly.

1. bundle install
2. Must check the settings
3. open settings.yml

  Required:
    :solution_directory
    Input your project directory existing .sln file.
    
    :resource_directory
    Input your resource directory existing .resx file.
    
      You can see this references on public site.
      https://developer.xamarin.com/guides/xamarin-forms/advanced/localization/
  
    :resource_file_name
    Input your resource file name without extension.
    
    :target_dir
    Input a directory name for new created files for localization

  Optional:
    :project_name
    Input a Project name if your project name is not same from solution name.
  
4. IMPORT
    Commit of backup your source before execute this script. 
    This script overwrite your localization files.
    If you wanna overwrite your source, you can comment last source code, 'lg.push_files'

