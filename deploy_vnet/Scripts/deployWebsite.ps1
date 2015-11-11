Configuration TailspinToys
{
   
  Import-DscResource -Module xWebAdministration
  Import-DscResource -Module xNetworking
  Import-DscResource -Module xSqlPs
  Import-DscResource -Module xDatabase
  #http://www.vexasoft.com/blogs/powershell/9561687-powershell-4-desired-state-configuration-enforce-ntfs-permissions
  Import-DscResource -Module NTFSPermission

  Node $AllNodes.NodeName 
  { 
    

    #Install the IIS Role 
    WindowsFeature IIS 
    { 
      Ensure = “Present” 
      Name = “Web-Server” 
    } 

    #Install ASP.NET 4.5 
    WindowsFeature ASP 
    { 
      Ensure = “Present” 
      Name = “Web-Asp-Net45” 
    } 

    xWebsite DefaultSite
    {
        Ensure = "Present"
        Name = "Default Web Site"
        PhysicalPath = "C:\inetpub\wwwroot"
        State = "Stopped"
        DependsOn = "[WindowsFeature]IIS"
    }

    File TailspinSourceFiles
    {
        Ensure = "Present"  # You can also set Ensure to "Absent"
        Type = "Directory“ # Default is “File”
        Recurse = $true
        SourcePath = $AllNodes.SourceDir + "_PublishedWebsites\Tailspin.Web" # This is a path that has web files
        DestinationPath = "C:\inetpub\dev\tailspintoys" # The path where we want to ensure the web files are present
    }

    
    #now change web config connection string
    Script ChangeConnectionString 
    {
        SetScript =
        {    
            $path = "C:\inetpub\dev\tailspintoys\Web.Config"
            [xml]$xml = Get-Content $path 

            $node = $xml.SelectSingleNode("//connectionStrings/add[@name='TailspinConnectionString']")
            $node.Attributes["connectionString"].Value = "Data Source=localhost;Initial Catalog=TailspinToys;User=sa;pwd=xxx;Max Pool Size=1000"
            $xml.Save($path)
        }
        TestScript = 
        {
            return $false
        }
        GetScript = 
        {
            return @{
                GetScript = $GetScript
                SetScript = $SetScript
                TestScript = $TestScript
                Result = false
            }
        } 
    }
    

    NTFSPermission AppDataSecurity
    {
        Ensure = "Present"
        Account = "IIS AppPool\DefaultAppPool"
        Access = "Allow"
        Path = "C:\inetpub\dev\tailspintoys\app_data"
        Rights = "FullControl"
    } 

    xWebsite TailspinToysSiteDev
    {
        Ensure = "Present"
        Name = "Dev-Tailspintoys"
        PhysicalPath = "C:\inetpub\dev\tailspintoys"
        State = "Started"
        BindingInfo     = MSFT_xWebBindingInformation  
        {  
            Protocol              = "HTTP"  
            Port                  = 11000
        }  

        DependsOn = "[WindowsFeature]IIS"
    }

    xFirewall Firewall
    {
        Name                  = "TailpinToys Dev"
        DisplayName           = "Firewall Rule for TailpinToys Dev"
        DisplayGroup          = "Tailspin"
        Ensure                = "Present"
        Access                = "Allow"
        State                 = "Enabled"
        Profile               = ("Domain")
        Direction             = "InBound"
        LocalPort             = ("11000")         
        Protocol              = "TCP"
        Description           = "Firewall Rule for TailpinToys Dev"  
    }

   

    #database deploy

  
    

    
    
  } 

}

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName="WebTest2"
            SourceDir = "\\neuromancer\Drops\TailspinToys_CD_WebTest1\TailspinToys_CD_WebTest1_20140213.1\"
            PSDscAllowPlainTextPassword=$true
            RebootNodeIfNeeded = $true
         }
   )
}