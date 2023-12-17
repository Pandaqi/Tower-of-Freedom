**GAMEPLAY:**

-   *Questions if they're good enough:* platform generation/density, music balance,

***TO HOTBAR OR NOT TO HOTBAR***

-   Physically dropping and picking up tools is one of the basic aspects of the game, and adds some extra dynamics, *especially* with two players.

-   I could add option for a *hotbar*, only in one player games. In this case, the player can access a tool immediately by pressing numbers 1-6.

-   If we want something similarly for two players, we could go for a *rotating system*. Then players have "next tool" and "previous tool" buttons, and need to remember the order very well

**CONTROLS:** Three options -- pick one

-   Leave it as is. The controls are fine, I think, and everything works neatly with them, so why change?

-   [[https://godotengine.org/qa/2080/save-record]{.underline}](https://godotengine.org/qa/2080/save-record) + Jan's *Squared* Code

-   Add configuration for the most important controls; the two special buttons. This means we need to add an extra entry to configure controls to the main menu, and save/load from a file

-   Add complete key rebinding. Add button to main menu saying "Options" or something, and allow the user to create a new key binding in the next screen

**OTHER COMMENTS:**

-   **Marketing:** GODOT showcase + Facebook + Reddit

-   Joystick support zou moeten zijn toegevoegd, geen manier om uit te testen :(

-   Tutorial werkt prima en in vrijwel alle gevallen, maar wie weet wat mensen voor rare dingen verzinnen

-   Change icon on end product to proper logo, if possible

OPTIONAL IDEAS

*( => **Teleporterende Spin:** Valt de spelers aan? Kunnen we geen betere monsters verzinnen? )*

*=> Sampleplayer seems fixed -- the problem was when the sound was exactly at the center of the camera*

*Terrible Tower Troubles (Origineel Idee, half uitgevoerd)*

**Level generatie:** Boven het bos zwevende wolken, en eventueel andere beesten

**Resources/Buying:** Wanneer iemand iets wil bouwen/kopen, schakelt het scherm naar splitscreen: het ene scherm laat gewoon de viewport zien waarin speler 1 verder speelt, het andere scherm laat alle mogelijke koopjes zien (de speler selecteert wat ie wil met pijltjes + speciale toets om te bevestigen)

Plaats random diamanten door het level, maak ze oppak-baar. Laat om de zoveel tijd een nieuwe verschijnen.

**Ending the game:** Zorg dat spelers het level winnen als ze een bepaalde hoogte bereiken? (Waar ze iets pakken? Of iemand bevrijden? Of door een portaal worden weggezogen? Zoiets)

**Monsters:** Teken monsters met simpele animaties voor hun beweging (en eventueel speciale actie). Wanneer monster toren (of poppetje) bereikt, doe iets wat slecht is :p

Je staat met z'n tweeën op een lage toren, in het midden van het "speelveld". Het doel is om de prinses te redden die ergens hoog aan een paal is opgehangen.

Waaruit bestaat het speelveld?

-   Gras/modder ondergrond, met in de achtergrond bomen en bergen enzo.

-   Een willekeurige samenstelling van bomen waar je in kunt klimmen, of kunt omhakken

-   Een willekeurige samenstelling van grotten/gesteenten waar je op kunt springen, of in kan schuilen, of kapot kunt maken

-   Power-ups (zoals diamanten ofzo) die soms verschijnen, maar ook willekeurige slechte dingen (zoals meteorietenregen of kanonskogels)

-   Willekeurige beesten en andere dingen die langs vliegen.

    -   Sommige beesten zijn goed en kun je gebruiken, anderen zijn slecht en moet je neerschieten.

    -   Soms zijn er plateau's waar je op kan staan, of loopbruggen tussen bomen

Wat kan iedere speler doen?

-   Elke speler kan links en rechts bewegen, springen, bukken en hun actie doen.

-   Elke speler kan maar één voorwerp tegelijk vasthebben -- dit voorwerp bepaalt wat de speler kan doen:

    -   **Boog:** Monsters op afstand neerschieten

    -   **Zwaard:** Monsters van dichtbij neermaaien

    -   **Bom:** Bommen plaatsen of gooien die (later) ontploffen

    -   **Bijl:** Bomen omhakken

    -   **Hamer:** Dingen opbouwen

    -   **Pikhouweel:** Steen hakken

-   Wanneer men genoeg materialen heeft kan men speciale dingen bouwen die ze kunnen helpen

-   Wanneer één iemand doodgaat, verliest men het spel. Wanneer de prinses wordt bevrijd, wint men het spel.

Wat doen de monsters?

-   Sommige monsters laten levens of andere dingen vallen als ze doodgaan

-   **??**: Een monster dat de poppetjes aanvalt, niet de toren?

-   **Trol:** Loopt langzaam op de toren af, en begint er op in te hakken

-   **Spin:** Kruipt over de toren omhoog

-   **Katapult:** Gooit kanonskogels

-   **Dwergen:** Bouwen dingen die de monsters helpen

-   **Draak**: Vliegt en spuwt vuur

-   **Eenhoorn**: Rent snel op de toren af en beukt er één keer keihard in (daarna gaat ie dood)

-   (**Vliegende Olifant**: Vliegt tot ie boven iemand zweeft, en laat zich er dan keihard bovenop vallen)

-   (**Uil:** Neemt een speler mee, waardoor deze tijdelijk niks kan doen en eventueel materiaal/leven verliest?)

-   (*Meer grondmonsters?*)

Waarom mag de toren niet afbreken?

-   Als een stuk aan beide kanten weg is, zakt de toren naar beneden, en moet je weer meer bouwen om op de goede hoogte te komen

Wat kan je bouwen/welk materiaal en andere dingen heb je?

-   Hout: In overvloed, erg belangrijk voor alles

-   Steen: Zuiniger mee zijn, essentieel voor sommige dingen

-   Diamanten: Zeldzaam, kun je inwisselen voor speciale dingen
