<%--
Header - header include
Author - David Benge
create date - 11-18-2010

this should be broken out once we get a grip on the ui more
Added client time zone cookie
--%>
<%@ page import="com.day.text.Text, com.day.cq.commons.Doctype" %>
<%@include file="/libs/foundation/global.jsp" %>
<%@ page import="java.util.*" %>
<cq:includeClientLib js="cq.widgets"/>

<%
//Setup and get propertys
String queryString = slingRequest.getQueryString();
if(queryString == null)
{
    queryString = "";
}
String authorStyle = properties.get("style",".gsa-search { width: 100%; } .search-form {} .search-form .search-submit { background-image: url('/apps/gsasearch/components/gsasearchresults/images/search-button.gif'); background-repeat: no-repeat; width : 36px; height : 25px; display: block; cursor : pointer; cursor : hand; } .search-results { width: 100%; } #searchbox{width: 250px} #search-results-panel { width: 100%; } .search-result { display: block; margin-bottom: 10px; width: 100%; } .search-result .title { width: 100%; } .search-result .title a { text-decoration: none; border-bottom: 1px dotted red; } .search-result .title a:hover { text-decoration: none; border-bottom: 1px dotted red; } .search-result .snippet { width: 100%; } .search-result .url { width: 100%; color: green; }.x-tbar-page-first{background-image: url(/libs/cq/ui/widgets/themes/default/ext/grid/page-first.gif) !important; background-repeat: no-repeat; background-position:center; background-color: transparent;}.x-tbar-page-prev{background-image: url(/libs/cq/ui/widgets/themes/default/ext/grid/page-prev.gif) !important; background-repeat: no-repeat; background-position:center; background-color: transparent;}.x-tbar-page-next{background-image: url(/libs/cq/ui/widgets/themes/default/ext/grid/page-next.gif) !important; background-repeat: no-repeat; background-position:center; background-color: transparent;}.x-tbar-page-last{background-image: url(/libs/cq/ui/widgets/themes/default/ext/grid/page-last.gif) !important; background-repeat: no-repeat; background-position:center; background-color: transparent;}.x-tbar-loading{background-image: url(/libs/cq/ui/widgets/themes/default/ext/grid/refresh.gif) !important; background-repeat: no-repeat; background-position:center; background-color: transparent;}div.keymatch{ background-color: #EFEFEF;  padding-bottom: .5em;  padding-left: .5em;  padding-top: .5em; margin-top: 1em; margin-bottom: 1em;}div.keymatch .label{}div.keymatch .label a{} div.keymatch .url{color: green;}");
String authorTemplate = properties.get("tpl","<tpl for=\".\"><div class=\"search-result\"><div class=\"title\"><a href=\"{U}\">{T}</a></div><div class=\"snippet\">{S}</div><div class=\"url\">{U}</div></div></tpl><div class=\"x-clear\"></div>");
String[] urlParams = properties.get("urlParams",new String[0]);
String[] collections = properties.get("searchCollections",new String[0]);
%>

<div class="gsa-search">
    <div class="search-form">
        <form name="form-search" id="form-search" >
            <table>
                <tr>
                    <td>
                        <%
                        if(slingRequest.getRequestParameter("q") != null)
                        {
                        %>
                        <input name="q" maxlength="256" id="searchbox" value="<%= slingRequest.getRequestParameter("q") %>"/>
                        <%
                        }else{
                        %>
                        <input name="q" maxlength="256" id="searchbox" value=""/>
                        <%} %>
                    </td>
                    <td>
                        <div class="search-submit" id="search-submit"></div>
                    </td>
                </tr>
           </table>
           
           <% if(collections.length > 0){ 
           %>
           <div id="collection-selection">
               Collection: <select name="select-collection" id="select-collection">
           <%
               for(int ic=0;ic<collections.length;ic++){
                   String[] collectionPair = collections[ic].split(":");
                   String collectionName = collectionPair[1];
                   String collectionValue = collectionPair[0];
           %>
           <%= collections[ic] %>
                   <option value=<%= collectionValue %>><%= collectionName %></option>
           <% 
               }
           %>
               </select> 
           </div>
           <%
           } %>
        </form>
    </div>  
    <div id="search-sugestions"></div>
    <div id="search-keymatch"></div>
    <div class="search-results" id="search-results">
    </div>
</div>

<style>
#form-search{
    position: relative;
    }
#collection-selection{
    position: absolute;
    right: 0em;
    top: .25em;
}     
</style>

<script type="text/javascript">
    CQ.Ext.onReady(function(){  
        var aaa = aaa || {};
        aaa.gsaSearch = aaa.gsaSearch || new GsaSearch();
        function GsaSearch(){
            var searchResultsDivId="searchResultsDivHome"; //the parent for the search results
            
            var gsaUrl="/services/aaa/gsa/searchproxy";
            
            var spellingSuggest=CQ.Ext.get('search-sugestions');
            
            var showSpellingSuggest = '<%= properties.get("showSpellingSuggestions","off") %>';

            var searchAsYouType = '<%= properties.get("searchAsYouType","off") %>';

            var showKeyMatch = '<%= properties.get("showKeyMatch","off") %>';

            var keyMatchDiv=CQ.Ext.get('search-keymatch');

            var resultSetSize = <%= properties.get("resultSetSize",20) %>;
            
            this.ds=new CQ.Ext.data.Store({
                    xtype:'store',
                    url: gsaUrl,
                    paramNames: {
                        start : 'start',  // The parameter name which specifies the start row
                        limit : 'num'  // The parameter name which specifies number of rows to return
                    },
                    reader: new CQ.Ext.data.XmlReader(
                        {
                            record: 'R',
                            id: '@N',
                            totalProperty: 'RES/M'
                        },
                        [
                         {name: 'U', mapping: 'U'},
                         {name: 'UE', mapping: 'UE'},
                         {name: 'S', mapping: 'S'},
                         {name: 'RK', mapping: 'RK'},
                         {name: 'CRAWLDATE', mapping: 'CRAWLDATE'},
                         {name: 'LANG', mapping: 'LANG'},
                         {name: 'T', mapping: 'T'}
                        ]
                         
                    ),
                    baseParams:{output: 'xml_no_dtd'},
                    listeners: {
                        'load': function(store,records,opts){ 
                        if(showSpellingSuggest == "on")
                        {
                            //Check for top level spelling tips
                            var xmlQ = this.reader.xmlData.getElementsByTagName("Spelling");
                            var suggestion="";
                
                            if(xmlQ.length > 0)
                            {
                                //show spelling sugestion
                                for(var i = 0; i < xmlQ[0].childNodes.length;i++)
                                {
                                    if(xmlQ[0].childNodes[i].tagName == "Suggestion")
                                    {
                                        suggestion += xmlQ[0].childNodes[i].textContent;
                                        //trim off the bold italic
                                        var start = 6;
                                        var end = (suggestion.length -8) -start;
                                        suggestion = suggestion.substr(start,end);
                                    }
                                }
                                spellingSuggest.dom.innerHTML = "<span class='spelling-suggest'>Did you mean:</span> <a onclick='spellingSuggestion_onClick(\""+suggestion+"\")'>" + suggestion + "</a>";
                            }
                            else
                            {
                                //hide the spelling sugestion 
                                spellingSuggest.dom.innerHTML = suggestion;
                            }
                        }

                        //Key Matches
                        if(showKeyMatch == "on"){
                             var keyMatchContent = "";
                             var xmlKeyMatches = this.reader.xmlData.getElementsByTagName("GM");
                             if(xmlKeyMatches.length > 0){
                                 for(iKm=0;iKm < xmlKeyMatches.length;iKm++){
                                     var keyMatchUrl = xmlKeyMatches[iKm].childNodes[0].childNodes[0].textContent;
                                     var keyMatchLabel = xmlKeyMatches[iKm].childNodes[1].childNodes[0].textContent;

                                     keyMatchContent += opts.scope.getKeyMatchHtml(keyMatchLabel,keyMatchUrl);
                                 }
                             }
                             //hide the Key Match area
                             keyMatchDiv.dom.innerHTML = keyMatchContent;
                             
                        }
                    }
                    }
           });
           
           this.tpl=new CQ.Ext.XTemplate('<%= authorTemplate%>');
           
           this.resultsView=new CQ.Ext.DataView({
                xtype:'dataview',
                store: this.ds,
                tpl: this.tpl,
                emptyText: 'No search results to display'
            });
            
            this.pagingBarBottom=new CQ.Ext.PagingToolbar({
                xtype:'paging',
                store: this.ds,
                pageSize: resultSetSize,
                displayInfo: true,
                displayMsg:CQ.I18n.getMessage("Displaying items {0} - {1} of {2}")
            });
            
            this.searchResultsPanel=new CQ.Ext.Panel({
                xtype:'panel',
                id:'search-results-panel',
                layout:'fit',
                collapsible:false,
                layout:'fit',
                items: [this.resultsView,this.pagingBarBottom],
                renderTo:'search-results'
            });
            
            /*************************************
             * searchButton_click - Event
             * when the search button is pressed or enter is pressed while focus is on the search box
             */
            this.searchButton_click=function(e,t)
            {
                var searchBox = CQ.Ext.get("searchbox");
                this.doSearch(searchBox.getValue());
            };

            /*************************************
             * Search Box - OnChange Event
             * Fired when search as you type is turned on
             */
            this.searchBox_onChange=function(e,t)
            {
                var searchBox = CQ.Ext.get("searchbox");
                this.doSearch(searchBox.getValue());
            };
            
            /************************************
             * searchBox_onFocus
             * @e {Event} object
             * @t {Target} object
             * 
             * when the search box gets focus we fire this function
             */
            this.searchBox_onFocus=function(e,t)
            {
            };
            
            /*******
             * Call the backend and issue a search
             */     
            this.doSearch=function(query)
            {
                this.ds.setBaseParam('q',CQ.Ext.get("searchbox").getValue());
                this.ds.load({scope:this});
            };
            
            /*******
             * Search for new spelling
             */     
            this.spellingSuggestion_onClick=function(newSpelling)
            {
                this.ds.setBaseParam('q',newSpelling);
                this.ds.load({scope:this});
            };

            /****
             * Get Search As You Type on off flag
             * returns on or off
             ****/
            this.getSearchAsYouType=function(){
                return searchAsYouType;
            };
            this.setSearchAsYouType=function(setVal){
                searchAsYouType = setVal;
            };

            /****
             * Get and Set Show Spelling Suggest
             * turning this on displays the search sugestions that are returned from the GSA
             * returns on or off
             ****/
            this.getShowSpellingSuggest=function(){
                return showSpellingSuggest;
            };
            this.setShowSpellingSuggest=function(setVal){
                showSpellingSuggest = setVal;
            };

            /****
             * Get and Set Show Google KeyMatch
             ****/
            this.getShowKeyMatch=function(){
                return showKeyMatch;
            };
            this.setShowKeyMatch=function(setVal){
                showKeyMatch = setVal;
            };

            /****
             * Get and Set the result set size
             ****/
            this.getResultSetSize=function(){
                return resultSetSize;
            };
            this.setResultSetSize=function(setVal){
                this.resultSetSize = setVal;
            };

            /*** 
             * Get the html output for a Keymatch
             ***/
            this.getKeyMatchHtml=function(label, url){
                var html=new Array();
                html.push("<div class='keymatch'>");
                html.push("<div class='label'>");
                html.push("<a href='"+url+"'>"+label+"</a>");
                html.push("</div>");//label div end
                html.push("<div class='url'>");
                html.push(url);//url div end
                html.push("</div>");//url div end
                html.push("</div>");//keymatch div end
                
                return html.join(" ");
            };
            
            //Init
            //init the quick tips
            CQ.Ext.QuickTips.init();
            CQ.Ext.get("search-submit").on('click',this.searchButton_click,this);
            CQ.Ext.get("searchbox").on('focus', this.searchBox_onFocus, this);
            //Trap the enter key on the search box
            var keyMap = new CQ.Ext.KeyMap(document, {
                key: 13, //Ext.EventObject.ENTER
                fn: this.searchButton_click,
                stopEvent: true,
                scope: this
            });
            //If auto search is on lets turn on this listener
            if(this.getSearchAsYouType() == 'on'){
                CQ.Ext.get("searchbox").on('keyup',this.searchBox_onChange,this);
            };
            
            <% 
            //if collections are defined we need to wire up the change hander on the select
            if(collections.length > 0){ 
            %>

            var searchCollectionElement = CQ.Ext.get("select-collection").on('change', function() {
                var collectionSelection = CQ.Ext.get("select-collection");
                this.ds.setBaseParam('site',collectionSelection.dom.value);
                this.ds.load({scope:this});
            },this);
            
            <%
            }
            %>
            
            //Setup the passed query values plus any set by author
            <%
            Enumeration passedUrlParams = request.getParameterNames();
            while(passedUrlParams.hasMoreElements())
            {
                String paramKey = passedUrlParams.nextElement().toString();
                   %>
            this.ds.setBaseParam('<%= paramKey %>','<%= slingRequest.getRequestParameter(paramKey) %>');
                   <%
            }
            
            %>
            //set the default set result set size
            this.ds.setBaseParam('num',resultSetSize);
            <%
            
            //Get the URL auto append keys from the component config. 
            //This is done after the URL get to override anything passed via the url
            for(String urlParam : urlParams){
                String[] paramPairs = urlParam.split("=");
                %>
            this.ds.setBaseParam('<%= paramPairs[0] %>','<%= paramPairs[1] %>');
                <%
            }
            %>

            //Now that all the base params are set lets load the dataset
            this.ds.load({scope:this});
        };
        
    });
</script>
  
<style type="text/css">
    <%= authorStyle %>
</style>