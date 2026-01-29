probleemstelling 1:
Een overgroot deel van klanteninformatie bevindt zich in OneNotes die zich op interne sharepoint-pagina's bevinden.
Dit zorgt voor duplicate informatie of problemen om de juiste informatie terug te vinden, aangezien ESC B.V. intussen is overgeschakeld naar RDM (Remote Desktop Manager).

Er zijn verschillende doelstellingen:
1) ervoor zorgen dat alle informatie uit de onenotes kan worden overgebracht naar RDM
2) ervoor zorgen dat elke gebruiker met machtiging nieuwe vaults kan aanmaken in RDM voor nieuwe klanten (elke klant vereist zijn eigen vault)
3) Klanten die zich reeds in RDM bevinden vallen nu onder één default-vault, wat prestatie- en veiligheidsissues met zich meebrengt. Ook deze moeten op een uniforme manier elk hun eigen vault kunnen krijgen.

Er bestaan echter geen kant-en-klare oplossingen om dit te verwezenlijken.

Bovendien kwamen reeds heel wat vraagstukken kijken bij de mogelijke aanpakken
- om data uit OneNote te halen kan je gebruik maken van Microsoft Graph of van een COM communicator. Een laatste optie is om de data pagina per pagina manueel te exporteren, wat teveel tijd vraagt.
  -- Probleem bij Microsoft Graph command line tools: hiervoor moet machtiging aangevraagd worden. Deze machtiging geeft je echter permissies op ALLE sharepoint-pagina's binnen het volledige bedrijf, wat niet de bedoeling is.
  --- Mogelijke oplossing: een machtiging aanvragen aan de admin die enkel voor één pagina gegeven wordt. Dit is goed om de correcte werking van scripts te testen, maar is geen goede oplossing binnen productie.
      Hier moet worden bekeken met de Sharepoint-beheerders wat een logischer oplossing zou zijn.

  -- Probleem met de COM component: deze werkwijze tracht om via COM de gegevens van een geopend notebook in de OneNote Desktop app te lezen.
     Deze werkwijze blijkt echter niet te lukken: het script vindt geen geopend notebook waardoor extractie niet mogelijk is.
     Pogingen om dit op te lossen waren: office-herstelmodule, restart van OneNote, restart van PC, maar de fout blijft.
     Mogelijke oorzaken kunnen zijn:
        *** Windows security policies die COM automation blokkeren
        *** Anti-virus software
        *** Bepaalde Office/Windows configuraties
        *** Corrupted COM registratie die zelfs repair niet fixt 

  -- Probleem met manuele verwerking: dit vraagt teveel tijd.

Aanvullende bedenkingen die moeten worden gemaakt:
- Azure OpenAI en Claude AI kunnen de informatie die wordt ingelezen uit OneNote analyseren. Echter: deze informatie komt dan ook bij de AI-provider terecht.
  Aangezien hier vertrouwelijke informatie in staat is dit een schending van de privacy van de klant, deze piste is dus uitgesloten
  -- Mogelijke pistes:
    --- gebruik van Ollama: deze analyse gebeurt volledig offline wat zorgt dat er geen privacy-issues zijn.
        Er werd een script klaargezet dat Ollama installeert en het vereiste pakket (3.2) gaat downloaden. Ollama is echter zeer resource-intensief, er zal dus moeten afgewacht worden of het script met Ollama niet teveel tijd zal vragen met de beschikbare resources. 
        Er moet overleg gepleegd worden met AI- of sharepointteam om te zien of er devices zijn met betere hardware, of er andere mogelijkheden zijn om prestaties te verbeteren
    --- Geen analyse uitvoeren. Dit zou betekenen dat alle informatie uit OneNote onder "documentatie" terecht komt in RDM. Dit zorgt opnieuw voor veel manueel werk, wat we trachten te vermijden.
  

