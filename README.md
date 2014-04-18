Bluetrain.io-Sync
=================

Template sync tool for Bluetrain.io

### Requirements
```
Ruby 1.9.3
RubyGems
Bundler
```

### Installation
```
git clone git@github.com:BluetrainMobile/Bluetrain.io-Sync.git
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

### Directory Structure
You can create the following directory structure or run:
```
./bluetrain.thor pull *directory* to create it.
```

OR create a directory with the following sub directories:

```
/templates/
/includes/
```
The templates directory only recognizes .html files.  The includes folder accepts any type of text based file (CSS, JS, etc)

### Available Liquid Tags
Bluetrain.io templates use the Liquid Templating Engine.  The following tags are current available.
```
{% region id:MyRegion %} <!-- Create a section of the template which is editable in the Page Editor -->
{% template title:TemplateTitle %} <!-- Write the contents of another template -->
{% include_url title:IncludeTitle %} <!-- Write the URL of the include file -->
{% menu type:html || json %} <!-- Write the contents of the menu structure in either HTML (unordered list) or JSON -->
{% menu_url type:html || json %} <!-- Write the url of the menu in either HTML or JSON -->
{% head %} <!-- Write the contents of the system head variable.  Including SEO optimizations made in the Page Editor -->
{% link id:page_id %} <!-- Write a link to the page with the specified ID -->
```
