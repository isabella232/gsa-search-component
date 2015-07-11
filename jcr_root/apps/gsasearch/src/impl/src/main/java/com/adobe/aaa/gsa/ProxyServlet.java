package com.adobe.aaa.gsa;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URL;
import java.util.Enumeration;

import javax.servlet.ServletException;

import org.apache.felix.scr.annotations.*;
import org.apache.felix.scr.annotations.sling.SlingServlet;
import org.apache.sling.api.SlingHttpServletRequest;
import org.apache.sling.api.SlingHttpServletResponse;
import org.apache.sling.api.servlets.SlingAllMethodsServlet;
import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Component(metatype=true,label="Adobe@Adobe GSA Search Proxy",description = "GSA Search Proxy")
@SlingServlet(methods = {"POST"},paths={"/services/aaa/gsa/searchproxy"},generateComponent=false)
public class ProxyServlet extends SlingAllMethodsServlet implements BundleActivator {

    private static final long serialVersionUID = 8795673847499208743L;
    private final static Logger log = LoggerFactory.getLogger(ProxyServlet.class);
    private BundleContext bundleContext;
    
    
    @Property(label="GSA search URL", description="This is the URL to your GSA's search interface. Do not include extra query parameters here.",value="http://kitnsearch.corp.adobe.com/search", propertyPrivate=false)
    static final String PROPERTY_GSA_SEARCH_URL = "gsa.url";
    private String gsaUrl = "http://kitnsearch.corp.adobe.com/search";
       
    @Override
    protected void doGet(SlingHttpServletRequest request, SlingHttpServletResponse response) throws ServletException, IOException {
        log.debug("ResourceTypePostServlet::doGet()");
        doCall(request,response,request.getQueryString());
    }
    
    @Override
    protected void doPost(SlingHttpServletRequest request, SlingHttpServletResponse response) throws ServletException, IOException {
        log.debug("ResourceTypePostServlet::doPost()");
        Enumeration<String> names = request.getParameterNames();
        String queryString =  "";
        int numParams = 0;
        while (names.hasMoreElements())
        {
            if(numParams>0)
            {
                queryString += "&";
            }
            
            String key = (String) names.nextElement();
            String[] value = request.getParameterValues(key);
            queryString += key + "=";
            for(int i = 0;i < value.length;i++)
            {
                queryString += value[i];
                if(i>0)
                {
                    queryString += ",";
                }
            }
          
            numParams++;
            
        }
        doCall(request,response,queryString);
    }
    
    private void doCall(SlingHttpServletRequest request, SlingHttpServletResponse response,String queryString) throws ServletException, IOException
    {
        log.debug("doCall");
        //logger.debug("queryString="+queryString);
        response.setContentType("text/xml");
        String gsaUrl = this.gsaUrl + "?"+queryString;
        log.info("gsaUrl="+gsaUrl);
        URL url = new URL(gsaUrl);
        BufferedReader reader = new BufferedReader(new InputStreamReader(url.openStream()));
        //String gsaResponse="";
        StringBuilder sb = new StringBuilder();
        String responseLine="";
        
        while((responseLine = reader.readLine()) != null)
        {
            //gsaResponse += responseLine;
            sb.append(responseLine);
        }
        reader.close();
        
        response.getOutputStream().print(sb.toString());
   }
    
   public void start(BundleContext context) throws Exception
   {
        this.bundleContext = context;
                
        log.info("### Starting ###");
        
        setProperties();
   }

   /*
    * (non-Javadoc)
    * 
    * @see
    * org.osgi.framework.BundleActivator#stop(org.osgi.framework.BundleContext)
    */
   public void stop(BundleContext context) throws Exception {
       log.info(context.getBundle().getSymbolicName() + " stopped");
   }
   
   protected void setProperties()
   {
        log.info("Setting Properties on the user profile import data service");
    
        String prop = (String) this.bundleContext.getProperty(PROPERTY_GSA_SEARCH_URL);
        if(prop != null) 
        {
            this.gsaUrl = prop;
        }
   }
}