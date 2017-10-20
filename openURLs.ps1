
$navOpenInBackgroundTab = 0x1000;
$ie = new-object -com InternetExplorer.Application
$ie.Navigate2("http://phm-los-ppp01/epicportal");
$ie.Navigate2("http://phm-los-ppp02/epicportal", $navOpenInBackgroundTab);
$ie.Navigate2("http://phm-los-pcp01/epicportal", $navOpenInBackgroundTab);
$ie.Navigate2("http://phm-los-pcp02/epicportal", $navOpenInBackgroundTab);
$ie.Visible = $true;



$navOpenInBackgroundTab = 0x1000;
$ie = new-object -com InternetExplorer.Application
$ie.Navigate2("http://phm-los-upp01/epicportal");
$ie.Navigate2("http://phm-los-upp02/epicportal", $navOpenInBackgroundTab);
$ie.Navigate2("http://phm-los-ucp01/epicportal", $navOpenInBackgroundTab);
$ie.Navigate2("http://phm-los-ucp02/epicportal", $navOpenInBackgroundTab);
$ie.Visible = $true;
