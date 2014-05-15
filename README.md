Bluetrain.io-Sync
=================

Template sync tool for Bluetrain.io

### Important Note
The sync tool is not currently running over SSL.  We advise you to use a test account while testing.  SSL will be available soon.

### Requirements
```
Ruby 1.9.3
RubyGems
Bundler
```

### Installation
```
git clone git@github.com:BluetrainMobile/Bluetrain.io-Sync.git
cd Bluetrain.io-Sync
bundle install
chmod +x bluetrain.thor
./bluetrain.thor
```

#### Getting Started / Usage
Create a new empty directory which you'd like to use for syncing.  Once created, run:
```
 ./bluetrain.thor pull *directory*.  
```
 This command will create the initial directory structure required for syncing and pull down any remote files for the specified website.  Your local changes will be overwritten.  To continously monitor the directory for changes and automatically push them to Bluetrain.io, run:
```
./bluetrain.thor sync *directory*
````
This process will run until you press ctrl^c.  Alternatively, you can push your changes manually by running:
```
./bluetrain.thor push *directory*
```
In both cases, remote files will be overwritten.  

#### Directory Structure
Your initial pull from Bluetrain.io will create a directory with the following sub directories:

```
/templates/
/includes/
/plugins/
```
The templates directory only recognizes .html files.  The includes folder accepts any type of text based file (CSS, JS, etc).  The plugins directory requires a special set of files, which are described in the next section.

### Developing Plugins
Plugins are setup by creating a sub-directory in the plugins folder.  The name of the folder will be assigned as the plugin name.  The contents of the folder should be one or more of the following files:

```
settings.json (REQUIRED)
edit.html (REQUIRED)
preview.html
publish.html
default.html
```

settings.json consists of a single key/value pair, but will be expanded on.  The value of this key determines if a content editor will see the plugin in the Page Editor:

```
{"enabled": true}
```

The edit.html file contains the content for the edit view in the Page Editor.  You can persist data by including an HTML form:

```
<form>
<input type='text' name='myvalue'>
</form>
```

If you want to access the data stored later (in the same view, or in another view within the same plugin) you can do so using liquid:

```
{{myvalue}}
```

preview.html defines the content that will be displayed when a user is in the Page Editor or in Browse Mode (prior to publishing).  publish.html contains the content that will be displayed when a user's site has been pushed to production (published).  In the case that the content is the same for both views, you can instead include a default.html file which will be used for both.

For Example: You may wish to have seperate preview and publish files for a form, allowing users to test before publishing their site, but keeping production data seperate.  In the case of an image slider, which behaves the same in production and staging, you could choose to only include the default.html file.

You can find additional examples here: https://github.com/BluetrainMobile/Bluetrain.io-Plugins

### Available Liquid Tags
Bluetrain.io templates use the Liquid Templating Engine.  The following tags are current available:
```
{% region id:MyRegion %} <!-- Create a section of the template which is editable in the Page Editor -->
{% template title:TemplateTitle %} <!-- Write the contents of another template -->
{% include_url title:IncludeTitle %} <!-- Write the URL of the include file -->
{% menu type:html || json %} <!-- Write the contents of the menu structure in either HTML (unordered list) or JSON -->
{% menu_url type:html || json %} <!-- Write the url of the menu in either HTML or JSON -->
{% head %} <!-- Write the contents of the system head variable.  Including SEO optimizations made in the Page Editor -->
{% link id:page_id %} <!-- Write a link to the page with the specified ID -->
```
