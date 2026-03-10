# Fountain Pen Inventory (FPN) -- Comprehensive Feature Documentation

## 1. Overview

**Fountain Pen Inventory** (FPN) is a FileMaker Pro Runtime application designed for fountain pen collectors and enthusiasts. It provides a comprehensive personal database for cataloging, reviewing, rating, and managing a fountain pen collection, along with companion features for tracking inks, ink recipes, manufacturers, and reference links.

The application was distributed as a standalone FileMaker Pro Runtime, meaning users did not need a FileMaker Pro license to run it. The underlying database uses FileMaker's proprietary format, which has been exported here to SQLite for analysis.

**Primary audience:** Fountain pen hobbyists and collectors who want to:
- Maintain a detailed inventory of their pens with physical specifications
- Write structured reviews covering every aspect of a pen (first impression, appearance, design, nib, filling system, cost/value)
- Rate pens numerically across multiple dimensions
- Track purchase/sale history with multi-currency support
- Manage photos of each pen (closed, open, posted, nib close-up, converter)
- Catalog their ink collection with detailed properties (pH, opacity, waterproofness, feathering, etc.)
- Record custom ink-mixing recipes
- Maintain a reference library of manufacturer information and web links
- Store personal profile/contact information

**Database structure:** 10 tables, 78 columns on the main Fountain Pens table alone, 31 columns on the Inks table, and supporting reference tables for Manufacturers, Finishes, Currencies (210 world currencies), Photos, Ink Recipes, Links, Change Log, and Interface (user profile/preferences).

---

## 2. Pen Tracking -- The "Fountain Pens" Table (78 Columns)

The heart of the application. Each record represents a single pen (or pen set) in the collection.

### 2.1 Identity and Classification

| Column | Description |
|--------|-------------|
| `Model` | The pen model name (e.g., "CS388", "Safari", "Duofold Jr", "Noir et Noir") |
| `Manufacturer` | The pen manufacturer (e.g., "Conway Stewart", "Waterman's", "Lamy", "Montblanc", "Parker") |
| `Manufacturer_and_Model` | Auto-computed concatenation of Manufacturer + Model (e.g., "Waterman's Thorobred", "Montblanc Noir et Noir") |
| `Description` | Free-text description of the pen (e.g., "Fountain pen and pencil set", "Sterling silver, cracked Ideal nib, floral pattern", "Comes in original box") |
| `Pen_Type` | Category/type of the pen (e.g., fountain pen, rollerball -- field exists but not populated in sample data) |
| `Record_ID` | Unique numeric identifier for the pen record |

### 2.2 Physical Attributes

| Column | Description |
|--------|-------------|
| `Color` | The pen's color/finish description (e.g., "Blue Marble", "Gray/Green Marble", "Gold", "Dark Silver", "Red", "Light, baby blue", "Silver with interesting lines") |
| `Primary_Material` | Primary material the pen is made from |
| `Body_Material` | Specific body material (separate from cap/trim material) |
| `Size` | Overall size classification of the pen |
| `Length` | Length of the pen (capped/closed) |
| `Length_Posted` | Length of the pen with cap posted on the barrel |
| `Diameter` | Barrel diameter |
| `Weight` | Weight of the pen |
| `Cap_Type` | How the cap attaches (e.g., screw-on, snap, slip) |
| `Year_Made` | Year or approximate era the pen was manufactured (e.g., "2000") |

### 2.3 Nib Details

| Column | Description |
|--------|-------------|
| `Nib_Stroke` | Nib width/size designation (e.g., "EF" for extra-fine, "M" for medium, plus F, B, BB, Stub, Italic, etc.) |
| `Nib_Material` | What the nib is made of (e.g., "14KT Gold", "14kt Gold", "Probably 14kt") |
| `Nib_Flex` | Whether the nib is flexible, semi-flex, firm, or nail-like |
| `Nib_Modification` | Any custom work done to the nib (e.g., grinding, smoothing, custom grinds by nibmeisters) |

### 2.4 Filling System

| Column | Description |
|--------|-------------|
| `Filler` | The ink filling mechanism. Observed values: **Lever**, **Cartridge**, **Piston**, **Cartridge/Converter**. The app likely supports other common types as well (Eyedropper, Vacuum, Aerometric, Snorkel, Plunger, etc.) |

### 2.5 Condition and Status

| Column | Description |
|--------|-------------|
| `Condition_Rating` | Numeric rating of the pen's physical condition |
| `New_Used` | Whether the pen was purchased new or used |
| `Repair_Required` | Description of any repairs the pen needs |
| `Repair_Cost` | Cost of repairs performed |
| `Repaired_By` | Who performed the repair work |

### 2.6 Review Sections (Long-Form Text)

The app structures pen reviews into distinct sections, each with its own dedicated text field. This mirrors the format commonly seen on fountain pen review blogs and the FountainPenNetwork (FPN) forum.

| Column | Description |
|--------|-------------|
| `First_Impression` | Narrative review of the user's first impression upon receiving/handling the pen |
| `Appearance` | Detailed review of the pen's visual aesthetics, finish quality, engravings, etc. |
| `Design` | Review of the pen's ergonomic and structural design choices |
| `Nib` | Review of nib performance -- smoothness, wetness, line variation, feedback |
| `Filling_System` | Review of how the filling mechanism works in practice |
| `CostAndValue` | Review of whether the pen is worth what was paid (value proposition) |
| `Conclusion` | Summary/wrap-up of the overall review |
| `Comments` | Additional free-form comments |
| `Miscellaneous` | Catch-all notes field. In practice, used for provenance notes and ID tracking (e.g., "ID #0012 Bought from Lambertville Flea Market for 100 USD on 9/8/2019. Thought it was a Montblanc Boehme, but I was told on FPN that it's a Noir et Noir...") |
| `_Review` | Internal/computed field, likely a compiled view of all review sections |

### 2.7 Purchase Information

| Column | Description |
|--------|-------------|
| `Purchase_Price` | Price paid for the pen (as entered, may include currency notation like "100 USD") |
| `Purchase_Date` | Date the pen was purchased |
| `Purchased_From` | Seller/venue (e.g., "Lambertville Flea Market") |
| `Shipping_Cost` | Shipping charges |
| `Retail_Price` | The pen's retail/list price (for comparison to what was actually paid) |
| `Purchase_Price_Currency` | The currency the purchase price is denominated in |
| `Localized_Purchase_Price` | Purchase price converted to the user's local currency |
| `Localized_Currency_Purchase_Price` | Display-formatted localized price |
| `Purchase_Price_Display` | Formatted display string for the purchase price (e.g., "100.00 ") |
| `Sum_Purchase_Price` | Running total / aggregate of purchase prices across the collection |

### 2.8 Valuation

| Column | Description |
|--------|-------------|
| `Current_Value` | Estimated current market value of the pen |
| `Valuation_Date` | Date the current value was assessed |

### 2.9 Selling / Disposition

| Column | Description |
|--------|-------------|
| `Selling_Price` | Price the pen was sold for |
| `Selling_Date` | Date of sale |
| `Sold_To` | Buyer information |
| `Traded_For` | If the pen was traded rather than sold, what it was traded for |
| `Qty_Sold` | Number of units sold (for sets or multiples) |
| `Sum_Selling_Price` | Running total / aggregate of selling prices across the collection |

### 2.10 Collection Statistics (Computed Fields)

| Column | Description |
|--------|-------------|
| `Quantity` | Number of this pen owned (defaults to 1) |
| `Total_Pens_in_Collection` | Global count of all pens in the database |
| `Get_Found_Count` | FileMaker function -- count of records in the current found set (used for "X of Y" display) |
| `Get_Record_Number` | FileMaker function -- the current record's position in the found set |

### 2.11 Photos (Inline on Pen Record)

The Fountain Pens table has built-in container/reference fields for key photos:

| Column | Description |
|--------|-------------|
| `Photo_Closed` | Photo of the pen with cap on |
| `Photo_Open` | Photo of the pen uncapped |
| `Photo_Posted` | Photo of the pen with cap posted on the barrel |
| `Photo_Nib` | Close-up photo of the nib |
| `Photo_Converter` | Photo of the converter or filling mechanism |
| `Photo_Closed_Caption` | Caption text for the closed photo |
| `Photo_Web_Directory` | Path/URL to a web directory for the pen's photos (for web publishing) |
| `_BigPic` | Internal field for displaying an enlarged photo view |

### 2.12 Integration and Metadata

| Column | Description |
|--------|-------------|
| `FPN_Username` | The user's FountainPenNetwork.com username (for integration/attribution when publishing reviews) |
| `_Datafile` | Internal FileMaker data file reference |
| `_Datafile_Filepath` | File path to the FileMaker data file |
| `_Spacer` | Layout spacer element (UI only, no data) |
| `zzzzRename` | Temporary/utility field (likely used during development for rename operations) |

---

## 3. Rating System

The application implements a structured **multi-dimensional rating system** with 8 rating fields. Each rating corresponds to a section of the pen review.

### 3.1 Review Category Ratings

Each of these ratings is a numeric score (the exact scale is not documented in the data, but based on typical FileMaker pen apps, it is likely **0--10** or **1--5 stars**):

| Rating Field | What It Measures |
|---|---|
| `First_Impression_Rating` | Score for first-impression experience -- unboxing, initial feel, excitement |
| `Appearance_Rating` | Score for visual appeal -- finish quality, color, aesthetics |
| `Design_Rating` | Score for ergonomic and functional design -- balance, clip, weight distribution, posting |
| `Nib_Rating` | Score for nib performance -- smoothness, ink flow, line quality, consistency |
| `Filling_System_Rating` | Score for how well the filling system works -- capacity, ease of filling, reliability |
| `CostAndValue_Rating` | Score for value proposition -- is the pen worth what was paid? |

### 3.2 Condition Rating

| Rating Field | What It Measures |
|---|---|
| `Condition_Rating` | Physical condition of the pen (likely on a scale from Poor to Mint). Separate from the review ratings; this is an objective assessment of wear, damage, and completeness |

### 3.3 Overall / Total Rating

| Rating Field | What It Measures |
|---|---|
| `Total_Rating` | Aggregate/composite score computed from the individual category ratings. This is likely a calculated field (average or weighted average of the six review ratings above) |

---

## 4. Photo Management -- The "Photos" Table

The Photos table provides a **one-to-many** photo gallery for each pen and ink record, supplementing the inline photo fields on the Fountain Pens table.

### 4.1 Schema (5 Columns)

| Column | Description |
|--------|-------------|
| `Record_ID` | Unique identifier for the photo record (auto-incrementing integer) |
| `FP_Record_ID` | Foreign key linking to the Fountain Pens table's `Record_ID` |
| `Photo` | Container field holding the actual image data (stored as hex-encoded binary references in the SQLite export, e.g., "01", "02", "0A", etc.) |
| `Caption` | Free-text caption describing the photo |
| `Inks_Record_ID` | Foreign key linking to the Inks table -- allows photos to be associated with ink records as well as pen records |

### 4.2 Data Observations

- **61 photos** across **11 pen records** in the sample data
- Photos are distributed across pens with varying counts (4--6 photos per pen is typical)
- The `Inks_Record_ID` field enables dual-purpose photos: a writing sample photo could be linked to both the pen used and the ink used
- Captions are available but not populated in the sample data
- The Photo field stores binary container data (in FileMaker, these would be rendered as inline images)

### 4.3 Photo Workflow

The app supports two complementary approaches to photos:
1. **Structured inline photos** on the Fountain Pens table (Photo_Closed, Photo_Open, Photo_Posted, Photo_Nib, Photo_Converter) for the standard "hero shots"
2. **Gallery photos** in the Photos table for unlimited additional images per pen

---

## 5. Ink Tracking -- The "Inks" Table (31 Columns)

A full-featured ink database that mirrors the depth of the pen tracking system.

### 5.1 Identity

| Column | Description |
|--------|-------------|
| `Record_ID` | Unique identifier for the ink record |
| `Ink_Name` | Name of the ink (e.g., "Waterman Serenity Blue", "Noodler's Black") |
| `Manufacturer` | Ink manufacturer |
| `FPN_Color_Category` | Color classification using FountainPenNetwork's standard color categories |

### 5.2 Ink Properties

| Column | Description |
|--------|-------------|
| `Color_Description` | Detailed description of the ink's color |
| `Special_Features` | Notable characteristics (e.g., bulletproof, lubricated, shimmer, sheening) |
| `Drying_Speed` | How quickly the ink dries on paper |
| `Opacity` | How opaque or transparent the ink is |
| `Waterproof_Rating` | Degree of water resistance (likely a scale or descriptive categories) |
| `Feathering` | How much the ink feathers/bleeds on paper |
| `pH` | Acidity/alkalinity of the ink (important for pen safety -- acidic inks can damage certain materials) |
| `Sunlight_Resistance` | How resistant the ink is to UV fading |
| `Saturation` | Color saturation/intensity |
| `Shading` | Degree of shading the ink produces (variation in color density based on ink pooling) |
| `SampleBottleMix` | Whether this is a sample, full bottle, or a custom mix |
| `Do_Not_Mix` | Safety flag indicating if this ink should not be mixed with others |

### 5.3 Ink Ratings

| Column | Description |
|--------|-------------|
| `Color_Rating` | Numeric rating of the ink's color |
| `Overall_Rating` | Composite rating for the ink |

### 5.4 Purchase Information

| Column | Description |
|--------|-------------|
| `Purchase_Date` | When the ink was purchased |
| `Purchase_Price` | Price paid |
| `Purchase_Price_Localized` | Price converted to local currency |
| `Purchased_From` | Vendor/store |
| `Retail_Price` | Retail/list price |
| `Shipping_Cost` | Shipping charges |
| `Purchase_Price_Currency` | Currency denomination |
| `Localized_Currency` | User's local currency for display |

### 5.5 Bottle Details

| Column | Description |
|--------|-------------|
| `Bottle_Volume` | Volume of the ink bottle (e.g., 50ml, 80ml) |
| `Bottle_Notes` | Notes about the bottle (packaging, design, special editions) |

### 5.6 Media

| Column | Description |
|--------|-------------|
| `Main_Photo` | Container field for the primary ink photo (bottle photo or swatch) |
| `Caption` | Caption for the photo |
| `Notes` | General notes about the ink |

---

## 6. Ink Recipes -- The "Ink Recipes" Table (10 Columns)

For collectors who mix custom inks, this table stores recipes and color experiments.

| Column | Description |
|--------|-------------|
| `Record_ID` | Unique identifier |
| `Name` | Name of the custom ink recipe (e.g., "Ocean Teal", "Warm Brown") |
| `Color_Description` | Description of the resulting color |
| `Recipe` | The actual mixing recipe -- proportions of component inks |
| `Notes` | Additional notes on the recipe (e.g., "let sit for 24 hours", "shake before use") |
| `FPN_Color_Category` | Color classification using FPN's standard categories |
| `Date_Created` | When the recipe was first created |
| `Date_Modified` | When the recipe was last updated |
| `_SortBy_Selector` | UI field for choosing how to sort the recipe list |
| `_SortBy` | Computed sort key based on the selector |

---

## 7. Reference Data Tables

### 7.1 Manufacturers Table (3 Columns)

A lookup table of pen and ink manufacturers.

| Column | Description |
|--------|-------------|
| `Record_ID` | Unique identifier |
| `Manufacturer` | Manufacturer name |
| `Country` | Country of origin |

This table feeds dropdown/value lists for the Manufacturer fields on both the Fountain Pens and Inks tables.

### 7.2 Finish Table (3 Columns)

A reference table of pen finish types with abbreviations.

| Column | Description |
|--------|-------------|
| `Finish` | Full name of the finish type (e.g., "Matte", "High Polish", "Brushed", "Lacquer", "Celluloid") |
| `Abbreviation` | Short code for the finish |
| `Record_ID` | Unique identifier |

### 7.3 Currencies Table (11 Columns)

A comprehensive world currency reference with **210 currencies**, providing multi-currency support for international collectors.

| Column | Description |
|--------|-------------|
| `Currency_Symbol` | The currency symbol (e.g., $, EUR, GBP) |
| `Country` | Country name |
| `Currency` | Full currency name (e.g., "Australian Dollar", "Armenian Dram", "Argentine Peso") |
| `Value_in_Dollars` | Exchange rate to US Dollars |
| `Subdivision` | Smallest currency unit (e.g., cents, pence) |
| `ISO4217_Code` | ISO 4217 numeric code |
| `Currency_Code` | ISO 4217 alpha code (e.g., "USD", "GBP", "EUR", "AUD") |
| `Country_Currency` | Combined display string (e.g., "Australia - Australian Dollar") |
| `Regime` | Exchange rate regime information |
| `Num` | Numeric code |
| `Digits` | Number of decimal digits for the currency (e.g., 2 for most, 0 for JPY) |

This table enables the localized purchase price feature: users can enter purchase prices in any currency and have them automatically converted to their preferred local currency.

### 7.4 Links Table (7 Columns)

A curated directory of pen-related web resources.

| Column | Description |
|--------|-------------|
| `RecordID` | Unique identifier |
| `URL` | Web address |
| `Name` | Display name for the link |
| `Description` | What the link points to |
| `Type` | Category of link (e.g., "Forum", "Retailer", "Manufacturer", "Blog", "Reference") |
| `Valid` | Whether the link has been verified as still active |
| `Total_Links` | Count field (computed -- total number of links in the database) |

---

## 8. User Profile and Preferences -- The "Interface" Table (17 Columns)

A single-record table that stores the application's configuration and the user's personal information.

### 8.1 User Information

| Column | Description |
|--------|-------------|
| `First_Name` | User's first name |
| `Last_Name` | User's last name |
| `Address1` | Street address line 1 |
| `Address2` | Street address line 2 |
| `City` | City |
| `State` | State (US) |
| `Province` | Province (non-US) |
| `Zip` | Postal/ZIP code |
| `Country` | Country |
| `Phone` | Phone number |
| `Email` | Email address |
| `FPN_Username` | User's FountainPenNetwork.com forum username |

### 8.2 Application Settings

| Column | Description |
|--------|-------------|
| `Location_of_Pictures_Folder` | File path to the folder where pen/ink photos are stored on disk |
| `Currency` | User's preferred currency for price display and localization |
| `Version` | Current version of the FPN application |
| `Change_Log` | Inline change log or link to the Change Log table |
| `_HelpInfo` | Internal field storing help/documentation text for the app's help system |

---

## 9. Change Log -- The "Change Log" Table (6 Columns)

Tracks the version history and release notes for the FPN application itself (not user data changes).

| Column | Description |
|--------|-------------|
| `RecordID` | Unique identifier |
| `Date_Created` | Date the version/change was recorded |
| `Time_Created` | Time the version/change was recorded |
| `Change` | Description of what changed in this version |
| `Version` | Version number associated with the change |
| `_Change` | Internal/display variant of the change description |

---

## 10. User Interface -- Screens, Navigation & Workflows

The application is built in FileMaker Pro 8.5 and distributed as a standalone Runtime (.FPN file). The creator is Jon Rosen (jonro on FPN). Version 1.5 was released February 15, 2011. An estimated 3,000--4,000 collectors in 30+ countries use it.

### 10.1 Main Screens

The app has multiple layouts (screens), each serving a distinct purpose:

#### A. Fountain Pens -- Record View (Main Entry Screen)
The primary data entry form. Displays one pen at a time with all fields:
- **Header area**: Manufacturer & Model (auto-computed), pen image thumbnail
- **Identity section**: Model, Manufacturer, Description, Pen Type, Year of Manufacture (freeform text, e.g., "Circa 1937")
- **Physical specs**: Color, Primary Material, Body Material, Size, Length, Length Posted, Diameter, Weight, Cap Type
- **Nib section**: Nib Stroke, Nib Material, Nib Flex, Nib Modification
- **Filling system**: Filler type
- **Photos**: 5 structured inline photo slots -- Photo Closed, Photo Open, Photo Posted, Photo Nib, Photo Converter -- each with a caption field. Clicking a photo opens the **Big Photo view** with slideshow arrows to navigate between the 5 photos.
- **Purchase info**: Purchase Price, Purchase Date, Purchased From, Shipping Cost, Retail Price, Currency fields (buyer's native currency + purchase currency if different)
- **Sale info**: Selling Price, Selling Date, Sold To, Traded For, Qty Sold
- **Valuation**: Current Value, Valuation Date
- **Condition/Repair**: Condition Rating, New/Used, Repair Required, Repair Cost, Repaired By
- **Collection stats** (computed, read-only): Total Pens in Collection, record position in found set ("Record X of Y")
- **Navigation**: Previous/Next record buttons, record counter

#### B. Fountain Pens -- Reviews Layout
A dedicated tabbed layout for writing structured pen reviews. Each section has a large text area and a corresponding numeric rating field:

1. **First Impression** (+ First_Impression_Rating) -- Prompt: "Were you impressed, disappointed or were you indifferent?"
2. **Appearance** (+ Appearance_Rating) -- Prompt: "Is the pen a high gloss polish, or was it dull or matte finish? Is the pen uniform or are there inconsistencies?"
3. **Design/Size/Weight** (+ Design_Rating) -- Prompt: "Is it a cigar shaped pen, does it have a flat top, faux blind cap, spring loaded clip? Is the pen a small, semi, medium, regular, full size or oversize pen?"
4. **Nib** (+ Nib_Rating) -- Prompt: "Is the nib large, small, toothy, buttery smooth, flexy, semi-flexy or is it a rigid nail? Is this a good writer, is it fair, does it suck or is it a primo writer? Heavy flow, medium flow or is it a stingy writer, is it a dry writer?"
5. **Filling System** (+ Filling_System_Rating) -- Prompt: "Were there any issues like the converter not filling up to capacity?"
6. **Cost & Value** (+ CostAndValue_Rating) -- Prompt: "Is this pen worth the money you paid or you think it costs too much for what it is worth? Is this pen under rated, over rated or was it right on par?"
7. **Conclusion** -- Summary wrap-up text
8. **Total Rating** (computed from the above 6 ratings)

**Review-to-Clipboard**: After completing the review, clicking the **Review button** copies a fully formatted review to the clipboard, ready to paste into an FPN forum post. The review includes the FPN Username for attribution.

#### C. Fountain Pens -- List View
A scrollable table showing multiple pens at a glance:
- Columns: Manufacturer, Model, Color, and key summary fields
- **Purchase Price subtotal** displayed in the lower area
- **Sortable column headers**: clicking a column title sorts by that field
- **Sort icon** in the toolbar for multi-field sorting
- **Pen count** in the lower-left corner (automatically excludes pens marked as sold)
- **"Show Unsold Pens"** menu option to filter out sold pens

#### D. Fountain Pens -- Table View
Spreadsheet-like grid view:
- All records in rows, all fields in columns
- **Print icon** in toolbar
- Miscellaneous field shown instead of Conclusion
- Users can show/hide columns and rearrange them

#### E. Big Photo View
Enlarged photo display:
- Opens when clicking a photo in the Record View
- **Slideshow arrows** (left/right) to cycle through the 5 inline photos (Closed, Open, Posted, Nib, Converter)
- Caption displayed below the photo

#### F. Inks Layout
Complete ink database with all ink fields:
- Identity: Ink Name, Manufacturer, FPN Color Category
- Properties: Color Description, Special Features, Drying Speed, Opacity, Waterproof Rating, Feathering, pH, Sunlight Resistance, Saturation, Shading, Sample/Bottle/Mix, Do Not Mix
- Ratings: Color Rating, Overall Rating
- Purchase info: same structure as pens (price, date, vendor, currency)
- Photo: Main Photo + Caption
- **Ink Recipes tab**: A portal (sub-table) embedded in the Inks layout showing ink recipes. Each recipe has: Name, Color Description, Recipe instructions, Notes, FPN Color Category, Date Created, Date Modified, sortable by user-selected field.

#### G. Manufacturers Layout
Reference list of pen/ink manufacturers with Country field. Users can add/edit entries. Feeds dropdown value lists for Manufacturer fields on Pens and Inks.

#### H. Finishes Layout
Reference list of finish types (Matte, High Polish, Brushed, Lacquer, Celluloid, etc.) with abbreviations.

#### I. Links Layout
Curated directory of pen-related web resources: URL, Name, Description, Type (Forum, Retailer, Manufacturer, Blog, Reference), Valid flag. Total Links count.

#### J. Interface/Settings Layout
Single-record settings screen:
- **User Profile**: First Name, Last Name, Address (1 & 2), City, State, Province, Zip, Country, Phone, Email
- **FPN Username**: user's FountainPenNetwork.com forum name
- **Photo Folder Path**: location of pen/ink photos on disk
- **Preferred Currency**: user's home currency for price display
- **App Version** and **Change Log** display
- **Help Info**: built-in help text for the app

### 10.2 Menus & Keyboard Shortcuts

The app provides a custom **"Fountain Pens"** menu (Mac) with:
- **Sort** (Cmd-S / Ctrl-S): Opens a dialog to sort by any field or combination of fields. Users can add multiple sort fields and choose ascending/descending for each.
- **Find** (Cmd-F / Ctrl-F): Enter Find mode to search across any field
- **Show Unsold Pens**: Filters the found set to exclude pens with a Selling Date
- **Import from Previous Version**: Imports data from an older FPI database file (v1.0 → v1.5 migration)
- **Print**: Print the current record or found set
- Standard FileMaker navigation shortcuts (Cmd-Left/Right for Previous/Next record)

### 10.3 Key Workflows

#### Adding a New Pen
1. User clicks New Record (or Cmd-N)
2. Fills in identity, physical specs, nib details, filling system
3. Adds photos by clicking each photo container (Closed, Open, Posted, Nib, Converter)
4. Enters purchase information with currency selection
5. The pen is immediately counted in Total Pens in Collection

#### Writing a Review
1. Navigate to the Reviews layout for a pen
2. Fill in each review section (First Impression through Conclusion), guided by prompts
3. Set a numeric rating for each section
4. Total Rating is auto-computed
5. Click the **Review button** to copy the formatted review to clipboard
6. Paste into FPN forum post -- includes FPN Username attribution

#### Selling a Pen
1. Enter Selling Price, Selling Date, Sold To (or Traded For)
2. The pen is automatically excluded from the "unsold" count in List View
3. Sum Selling Price updates with the aggregate

#### Multi-Currency Purchase
1. Set your home currency in Interface/Settings
2. When entering a purchase price, select the Purchase Price Currency (e.g., GBP)
3. The app auto-converts to your home currency using the Currencies table exchange rate
4. Both original and localized prices are stored and displayed

#### Photo Management
1. **Inline photos**: Click each of the 5 structured photo containers to insert an image. Photos can be stored as file references (pointing to the Photo Folder Path) or embedded in the database.
2. **Gallery photos**: Additional photos added via the Photos table -- unlimited per pen, with optional captions, and can be cross-linked to Inks.
3. **Big Photo view**: Click any inline photo to see it enlarged with slideshow navigation.
4. **Web publishing**: The Photo_Web_Directory field stores a URL path for online photo hosting.

#### Data Import
- **From Excel/CSV**: Import tabular data into pen records
- **From Previous FPI Version**: Under the Fountain Pens menu, select Import. The app detects whether you're importing from v1.0 (original) or a newer version and handles field mapping accordingly. The old database must be closed before importing.

### 10.4 Platform Notes

- **Mac version**: Superior visual appearance due to font rendering; uses Cmd-key shortcuts
- **PC version**: Minor font adjustments; uses Ctrl-key shortcuts. Some users run the PC version on Linux via Wine.
- Both versions use the same .FPN database format and are data-compatible.

---

## 11. Data Model Summary

```
Interface (1 record)
    |
    +-- User profile, preferences, currency setting
    |
Fountain Pens (main collection)
    |-- Record_ID (PK)
    |-- 78 columns covering identity, physical specs, nib, filling system,
    |   condition, 8 ratings, 7 review text sections, purchase/sale info,
    |   5 inline photo fields, collection stats
    |
    +--< Photos (1-to-many)
    |       |-- FP_Record_ID (FK -> Fountain Pens.Record_ID)
    |       |-- Inks_Record_ID (FK -> Inks.Record_ID)
    |       |-- Photo (container), Caption
    |
    +-- Manufacturer -> Manufacturers (lookup)
    |
Inks (ink collection)
    |-- Record_ID (PK)
    |-- 31 columns covering identity, 10 ink properties (pH, opacity,
    |   waterproof, feathering, saturation, shading, drying speed,
    |   sunlight resistance, special features, do-not-mix flag),
    |   2 ratings, purchase info, photo
    |
    +--< Photos (shared -- via Inks_Record_ID)
    |
Ink Recipes
    |-- Name, Recipe, Color_Description, Notes, FPN_Color_Category
    |
Manufacturers (reference)
    |-- Manufacturer, Country
    |
Finish (reference)
    |-- Finish name, Abbreviation
    |
Currencies (reference -- 210 records)
    |-- ISO codes, exchange rates, symbols, subdivisions
    |
Links (reference)
    |-- URL, Name, Description, Type, Valid flag
    |
Change Log (app version history)
    |-- Version, Date, Change description
```

---

## 12. Key Design Observations

1. **Review-centric workflow**: The app is structured around writing detailed pen reviews, not just cataloging. The six dedicated review text fields plus corresponding ratings mirror the structure of formal pen reviews on FountainPenNetwork.com.

2. **Full lifecycle tracking**: Pens can be tracked from acquisition (Purchase_Price, Purchased_From, Purchase_Date) through ownership (repairs, condition, valuation) to disposition (Selling_Price, Selling_Date, Sold_To, Traded_For).

3. **International support**: With 210 currencies, localized price fields, and Province/State/Country address fields, the app is designed for a global user base.

4. **Dual photo systems**: The inline photo fields (Closed, Open, Posted, Nib, Converter) provide a structured "review photo set," while the Photos table allows unlimited gallery photos with captions.

5. **Ink-pen cross-referencing**: The Photos table's dual foreign keys (FP_Record_ID and Inks_Record_ID) allow writing sample photos to be linked to both the pen and ink used, enabling cross-referencing.

6. **Scientific ink properties**: The Inks table goes beyond simple cataloging to include technical properties like pH (important for pen safety), opacity, saturation, and waterproofness -- data points valued by serious ink enthusiasts.

7. **Collection analytics**: Computed fields like Total_Pens_in_Collection, Sum_Purchase_Price, and Sum_Selling_Price provide at-a-glance collection statistics and financial tracking.

---

## 13. Version History

### v1.0 (Original Release, ~2006)
- Core pen database with descriptive fields, purchase info, photos, and review sections
- Mac and PC versions
- Basic sorting and searching

### v1.5 (February 15, 2011)
Major update incorporating community feedback:
- **Inks module**: Complete ink database with 31 fields + ink recipes portal
- **International currency**: Two currency fields (buyer's + seller's) with 210-currency table
- **Year of Manufacture**: Freeform text field (e.g., "Circa 1937")
- **FPN Username**: Added to user profile
- **List View**: Purchase price subtotal, sortable column headers, sort icon
- **Table View**: Print icon, "Show Unsold Pens" menu, Miscellaneous replaces Conclusion
- **Reviews**: Design field expanded to "Design/Size/Weight", ratings display, Review button repositioned
- **Big Photo**: Slideshow arrows for cycling through inline photos
- **Navigation menu**: Improved keyboard shortcuts
- **Import tool**: Migrate data from v1.0 to v1.5
- Enlarged Description and Miscellaneous fields
- Various bug fixes (caption display, review generation tab)

---

## 14. Distribution & Licensing

- **Creator**: Jon Rosen (jonro on FPN, jonro.com)
- **License**: Freeware -- "my gift to the FPN fountain pen community"
- **Restrictions**: Cannot charge for redistribution, cannot modify, cannot present as your own work
- **User base**: Estimated 3,000--4,000 collectors in 30+ countries
- **Downloads**: ~2,000 from FPN alone (as of last count)
- **Built with**: FileMaker Pro 8.5, distributed as FileMaker Runtime (.FPN)
- **Compatibility**: Runs on macOS (PPC/Intel only -- breaks on newer macOS), Windows, Linux (via Wine)

---

## 15. Sources

- FPN forum thread: "Fountain Pen Database Available for Download" (original announcement)
- FPN forum thread: "New Version of FPI Database (Version 1.5) Ready to Download" (v1.5 changelog)
- FPN file download page: "Fountain Pen Inventory Database by Jon Rosen"
- SQLite export of the actual database (14 pen records, 61 photos, 210 currencies)
