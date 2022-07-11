CREATE SCHEMA Production
  CREATE TABLE BillOfMaterials(
    BillOfMaterialsID SERIAL NOT NULL, -- int
    ProductAssemblyID INT NULL,
    ComponentID INT NOT NULL,
    StartDate TIMESTAMP NOT NULL CONSTRAINT "DF_BillOfMaterials_StartDate" DEFAULT (NOW()),
    EndDate TIMESTAMP NULL,
    UnitMeasureCode char(3) NOT NULL,
    BOMLevel smallint NOT NULL,
    PerAssemblyQty decimal(8, 2) NOT NULL CONSTRAINT "DF_BillOfMaterials_PerAssemblyQty" DEFAULT (1.00),
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_BillOfMaterials_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_BillOfMaterials_EndDate" CHECK ((EndDate > StartDate) OR (EndDate IS NULL)),
    CONSTRAINT "CK_BillOfMaterials_ProductAssemblyID" CHECK (ProductAssemblyID <> ComponentID),
    CONSTRAINT "CK_BillOfMaterials_BOMLevel" CHECK (((ProductAssemblyID IS NULL)
        AND (BOMLevel = 0) AND (PerAssemblyQty = 1.00))
        OR ((ProductAssemblyID IS NOT NULL) AND (BOMLevel >= 1))),
    CONSTRAINT "CK_BillOfMaterials_PerAssemblyQty" CHECK (PerAssemblyQty >= 1.00)
  )
  CREATE TABLE Culture(
    CultureID char(6) NOT NULL,
    Name "Name" NOT NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_Culture_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE Document(
    Doc varchar NULL,-- hierarchyid, will become DocumentNode
    DocumentLevel INTEGER, -- AS DocumentNode.GetLevel(),
    Title varchar(50) NOT NULL,
    Owner INT NOT NULL,
    FolderFlag "Flag" NOT NULL CONSTRAINT "DF_Document_FolderFlag" DEFAULT (false),
    FileName varchar(400) NOT NULL,
    FileExtension varchar(8) NULL,
    Revision char(5) NOT NULL,
    ChangeNumber INT NOT NULL CONSTRAINT "DF_Document_ChangeNumber" DEFAULT (0),
    Status smallint NOT NULL, -- tinyint
    DocumentSummary text NULL,
    Document bytea  NULL, -- varbinary
    rowguid uuid NOT NULL UNIQUE CONSTRAINT "DF_Document_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_Document_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_Document_Status" CHECK (Status BETWEEN 1 AND 3)
  )
  CREATE TABLE ProductCategory(
    ProductCategoryID SERIAL NOT NULL, -- int
    Name "Name" NOT NULL,
    rowguid uuid NOT NULL CONSTRAINT "DF_ProductCategory_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductCategory_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE ProductSubcategory(
    ProductSubcategoryID SERIAL NOT NULL, -- int
    ProductCategoryID INT NOT NULL,
    Name "Name" NOT NULL,
    rowguid uuid NOT NULL CONSTRAINT "DF_ProductSubcategory_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductSubcategory_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE ProductModel(
    ProductModelID SERIAL NOT NULL, -- int
    Name "Name" NOT NULL,
    CatalogDescription XML NULL, -- XML(Production.ProductDescriptionSchemaCollection)
    Instructions XML NULL, -- XML(Production.ManuInstructionsSchemaCollection)
    rowguid uuid NOT NULL CONSTRAINT "DF_ProductModel_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductModel_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE Product(
    ProductID SERIAL NOT NULL, -- int
    Name "Name" NOT NULL,
    ProductNumber varchar(25) NOT NULL,
    MakeFlag "Flag" NOT NULL CONSTRAINT "DF_Product_MakeFlag" DEFAULT (true),
    FinishedGoodsFlag "Flag" NOT NULL CONSTRAINT "DF_Product_FinishedGoodsFlag" DEFAULT (true),
    Color varchar(15) NULL,
    SafetyStockLevel smallint NOT NULL,
    ReorderPoint smallint NOT NULL,
    StandardCost numeric NOT NULL, -- money
    ListPrice numeric NOT NULL, -- money
    Size varchar(5) NULL,
    SizeUnitMeasureCode char(3) NULL,
    WeightUnitMeasureCode char(3) NULL,
    Weight decimal(8, 2) NULL,
    DaysToManufacture INT NOT NULL,
    ProductLine char(2) NULL,
    Class char(2) NULL,
    Style char(2) NULL,
    ProductSubcategoryID INT NULL,
    ProductModelID INT NULL,
    SellStartDate TIMESTAMP NOT NULL,
    SellEndDate TIMESTAMP NULL,
    DiscontinuedDate TIMESTAMP NULL,
    rowguid uuid NOT NULL CONSTRAINT "DF_Product_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_Product_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_Product_SafetyStockLevel" CHECK (SafetyStockLevel > 0),
    CONSTRAINT "CK_Product_ReorderPoint" CHECK (ReorderPoint > 0),
    CONSTRAINT "CK_Product_StandardCost" CHECK (StandardCost >= 0.00),
    CONSTRAINT "CK_Product_ListPrice" CHECK (ListPrice >= 0.00),
    CONSTRAINT "CK_Product_Weight" CHECK (Weight > 0.00),
    CONSTRAINT "CK_Product_DaysToManufacture" CHECK (DaysToManufacture >= 0),
    CONSTRAINT "CK_Product_ProductLine" CHECK (UPPER(ProductLine) IN ('S', 'T', 'M', 'R') OR ProductLine IS NULL),
    CONSTRAINT "CK_Product_Class" CHECK (UPPER(Class) IN ('L', 'M', 'H') OR Class IS NULL),
    CONSTRAINT "CK_Product_Style" CHECK (UPPER(Style) IN ('W', 'M', 'U') OR Style IS NULL),
    CONSTRAINT "CK_Product_SellEndDate" CHECK ((SellEndDate >= SellStartDate) OR (SellEndDate IS NULL))
  )
  CREATE TABLE ProductCostHistory(
    ProductID INT NOT NULL,
    StartDate TIMESTAMP NOT NULL,
    EndDate TIMESTAMP NULL,
    StandardCost numeric NOT NULL,  -- money
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductCostHistory_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_ProductCostHistory_EndDate" CHECK ((EndDate >= StartDate) OR (EndDate IS NULL)),
    CONSTRAINT "CK_ProductCostHistory_StandardCost" CHECK (StandardCost >= 0.00)
  )
  CREATE TABLE ProductDescription(
    ProductDescriptionID SERIAL NOT NULL, -- int
    Description varchar(400) NOT NULL,
    rowguid uuid NOT NULL CONSTRAINT "DF_ProductDescription_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductDescription_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE ProductDocument(
    ProductID INT NOT NULL,
    Doc varchar NOT NULL, -- hierarchyid, will become DocumentNode
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductDocument_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE Location(
    LocationID SERIAL NOT NULL, -- smallint
    Name "Name" NOT NULL,
    CostRate numeric NOT NULL CONSTRAINT "DF_Location_CostRate" DEFAULT (0.00), -- smallmoney -- money
    Availability decimal(8, 2) NOT NULL CONSTRAINT "DF_Location_Availability" DEFAULT (0.00),
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_Location_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_Location_CostRate" CHECK (CostRate >= 0.00),
    CONSTRAINT "CK_Location_Availability" CHECK (Availability >= 0.00)
  )
  CREATE TABLE ProductInventory(
    ProductID INT NOT NULL,
    LocationID smallint NOT NULL,
    Shelf varchar(10) NOT NULL,
    Bin smallint NOT NULL, -- tinyint
    Quantity smallint NOT NULL CONSTRAINT "DF_ProductInventory_Quantity" DEFAULT (0),
    rowguid uuid NOT NULL CONSTRAINT "DF_ProductInventory_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductInventory_ModifiedDate" DEFAULT (NOW()),
--    CONSTRAINT "CK_ProductInventory_Shelf" CHECK ((Shelf LIKE 'AZa-z]') OR (Shelf = 'N/A')),
    CONSTRAINT "CK_ProductInventory_Bin" CHECK (Bin BETWEEN 0 AND 100)
  )
  CREATE TABLE ProductListPriceHistory(
    ProductID INT NOT NULL,
    StartDate TIMESTAMP NOT NULL,
    EndDate TIMESTAMP NULL,
    ListPrice numeric NOT NULL,  -- money
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductListPriceHistory_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_ProductListPriceHistory_EndDate" CHECK ((EndDate >= StartDate) OR (EndDate IS NULL)),
    CONSTRAINT "CK_ProductListPriceHistory_ListPrice" CHECK (ListPrice > 0.00)
  )
  CREATE TABLE Illustration(
    IllustrationID SERIAL NOT NULL, -- int
    Diagram XML NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_Illustration_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE ProductModelIllustration(
    ProductModelID INT NOT NULL,
    IllustrationID INT NOT NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductModelIllustration_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE ProductModelProductDescriptionCulture(
    ProductModelID INT NOT NULL,
    ProductDescriptionID INT NOT NULL,
    CultureID char(6) NOT NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductModelProductDescriptionCulture_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE ProductPhoto(
    ProductPhotoID SERIAL NOT NULL, -- int
    ThumbNailPhoto bytea NULL,-- varbinary
    ThumbnailPhotoFileName varchar(50) NULL,
    LargePhoto bytea NULL,-- varbinary
    LargePhotoFileName varchar(50) NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductPhoto_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE ProductProductPhoto(
    ProductID INT NOT NULL,
    ProductPhotoID INT NOT NULL,
    "primary" "Flag" NOT NULL CONSTRAINT "DF_ProductProductPhoto_Primary" DEFAULT (false),
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductProductPhoto_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE ProductReview(
    ProductReviewID SERIAL NOT NULL, -- int
    ProductID INT NOT NULL,
    ReviewerName "Name" NOT NULL,
    ReviewDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductReview_ReviewDate" DEFAULT (NOW()),
    EmailAddress varchar(50) NOT NULL,
    Rating INT NOT NULL,
    Comments varchar(3850),
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductReview_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_ProductReview_Rating" CHECK (Rating BETWEEN 1 AND 5)
  )
  CREATE TABLE ScrapReason(
    ScrapReasonID SERIAL NOT NULL, -- smallint
    Name "Name" NOT NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ScrapReason_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE TransactionHistory(
    TransactionID SERIAL NOT NULL, -- INT IDENTITY (100000, 1)
    ProductID INT NOT NULL,
    ReferenceOrderID INT NOT NULL,
    ReferenceOrderLineID INT NOT NULL CONSTRAINT "DF_TransactionHistory_ReferenceOrderLineID" DEFAULT (0),
    TransactionDate TIMESTAMP NOT NULL CONSTRAINT "DF_TransactionHistory_TransactionDate" DEFAULT (NOW()),
    TransactionType char(1) NOT NULL,
    Quantity INT NOT NULL,
    ActualCost numeric NOT NULL,  -- money
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_TransactionHistory_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_TransactionHistory_TransactionType" CHECK (UPPER(TransactionType) IN ('W', 'S', 'P'))
  )
  CREATE TABLE TransactionHistoryArchive(
    TransactionID INT NOT NULL,
    ProductID INT NOT NULL,
    ReferenceOrderID INT NOT NULL,
    ReferenceOrderLineID INT NOT NULL CONSTRAINT "DF_TransactionHistoryArchive_ReferenceOrderLineID" DEFAULT (0),
    TransactionDate TIMESTAMP NOT NULL CONSTRAINT "DF_TransactionHistoryArchive_TransactionDate" DEFAULT (NOW()),
    TransactionType char(1) NOT NULL,
    Quantity INT NOT NULL,
    ActualCost numeric NOT NULL,  -- money
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_TransactionHistoryArchive_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_TransactionHistoryArchive_TransactionType" CHECK (UPPER(TransactionType) IN ('W', 'S', 'P'))
  )
  CREATE TABLE UnitMeasure(
    UnitMeasureCode char(3) NOT NULL,
    Name "Name" NOT NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_UnitMeasure_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE WorkOrder(
    WorkOrderID SERIAL NOT NULL, -- int
    ProductID INT NOT NULL,
    OrderQty INT NOT NULL,
    StockedQty INT, -- AS ISNULL(OrderQty - ScrappedQty, 0),
    ScrappedQty smallint NOT NULL,
    StartDate TIMESTAMP NOT NULL,
    EndDate TIMESTAMP NULL,
    DueDate TIMESTAMP NOT NULL,
    ScrapReasonID smallint NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_WorkOrder_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_WorkOrder_OrderQty" CHECK (OrderQty > 0),
    CONSTRAINT "CK_WorkOrder_ScrappedQty" CHECK (ScrappedQty >= 0),
    CONSTRAINT "CK_WorkOrder_EndDate" CHECK ((EndDate >= StartDate) OR (EndDate IS NULL))
  )
  CREATE TABLE WorkOrderRouting(
    WorkOrderID INT NOT NULL,
    ProductID INT NOT NULL,
    OperationSequence smallint NOT NULL,
    LocationID smallint NOT NULL,
    ScheduledStartDate TIMESTAMP NOT NULL,
    ScheduledEndDate TIMESTAMP NOT NULL,
    ActualStartDate TIMESTAMP NULL,
    ActualEndDate TIMESTAMP NULL,
    ActualResourceHrs decimal(9, 4) NULL,
    PlannedCost numeric NOT NULL, -- money
    ActualCost numeric NULL,  -- money
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_WorkOrderRouting_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_WorkOrderRouting_ScheduledEndDate" CHECK (ScheduledEndDate >= ScheduledStartDate),
    CONSTRAINT "CK_WorkOrderRouting_ActualEndDate" CHECK ((ActualEndDate >= ActualStartDate)
        OR (ActualEndDate IS NULL) OR (ActualStartDate IS NULL)),
    CONSTRAINT "CK_WorkOrderRouting_ActualResourceHrs" CHECK (ActualResourceHrs >= 0.0000),
    CONSTRAINT "CK_WorkOrderRouting_PlannedCost" CHECK (PlannedCost > 0.00),
    CONSTRAINT "CK_WorkOrderRouting_ActualCost" CHECK (ActualCost > 0.00)
  );

COMMENT ON SCHEMA Production IS 'Contains objects related to products, inventory, and manufacturing.';

SELECT 'Copying data into Production.BillOfMaterials';
\copy Production.BillOfMaterials FROM './data/BillOfMaterials.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.Culture';
\copy Production.Culture FROM './data/Culture.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.Document';
\copy Production.Document FROM './data/Document.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.ProductCategory';
\copy Production.ProductCategory FROM './data/ProductCategory.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.ProductSubcategory';
\copy Production.ProductSubcategory FROM './data/ProductSubcategory.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.ProductModel';
\copy Production.ProductModel FROM './data/ProductModel.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.Product';
\copy Production.Product FROM './data/Product.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.ProductCostHistory';
\copy Production.ProductCostHistory FROM './data/ProductCostHistory.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.ProductDescription';
\copy Production.ProductDescription FROM './data/ProductDescription.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.ProductDocument';
\copy Production.ProductDocument FROM './data/ProductDocument.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.Location';
\copy Production.Location FROM './data/Location.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.ProductInventory';
\copy Production.ProductInventory FROM './data/ProductInventory.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.ProductListPriceHistory';
\copy Production.ProductListPriceHistory FROM './data/ProductListPriceHistory.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.Illustration';
\copy Production.Illustration FROM './data/Illustration.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.ProductModelIllustration';
\copy Production.ProductModelIllustration FROM './data/ProductModelIllustration.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.ProductModelProductDescriptionCulture';
\copy Production.ProductModelProductDescriptionCulture FROM './data/ProductModelProductDescriptionCulture.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.ProductPhoto';
\copy Production.ProductPhoto FROM './data/ProductPhoto.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.ProductProductPhoto';
\copy Production.ProductProductPhoto FROM './data/ProductProductPhoto.csv' DELIMITER E'\t' CSV;

-- This doesn't work:
-- SELECT 'Copying data into Production.ProductReview';
-- \copy Production.ProductReview FROM 'ProductReview.csv' DELIMITER '  ' CSV;

-- so instead ...
INSERT INTO Production.ProductReview (ProductReviewID, ProductID, ReviewerName, ReviewDate, EmailAddress, Rating, Comments, ModifiedDate) VALUES
 (1, 709, 'John Smith', '2013-09-18 00:00:00', 'john@fourthcoffee.com', 5, 'I can''t believe I''m singing the praises of a pair of socks, but I just came back from a grueling
3-day ride and these socks really helped make the trip a blast. They''re lightweight yet really cushioned my feet all day. 
The reinforced toe is nearly bullet-proof and I didn''t experience any problems with rubbing or blisters like I have with
other brands. I know it sounds silly, but it''s always the little stuff (like comfortable feet) that makes or breaks a long trip.
I won''t go on another trip without them!', '2013-09-18 00:00:00'),

 (2, 937, 'David', '2013-11-13 00:00:00', 'david@graphicdesigninstitute.com', 4, 'A little on the heavy side, but overall the entry/exit is easy in all conditions. I''ve used these pedals for 
more than 3 years and I''ve never had a problem. Cleanup is easy. Mud and sand don''t get trapped. I would like 
them even better if there was a weight reduction. Maybe in the next design. Still, I would recommend them to a friend.', '2013-11-13 00:00:00'),

 (3, 937, 'Jill', '2013-11-15 00:00:00', 'jill@margiestravel.com', 2, 'Maybe it''s just because I''m new to mountain biking, but I had a terrible time getting use
to these pedals. In my first outing, I wiped out trying to release my foot. Any suggestions on
ways I can adjust the pedals, or is it just a learning curve thing?', '2013-11-15 00:00:00'),

 (4, 798, 'Laura Norman', '2013-11-15 00:00:00', 'laura@treyresearch.net', 5, 'The Road-550-W from Adventure Works Cycles is everything it''s advertised to be. Finally, a quality bike that
is actually built for a woman and provides control and comfort in one neat package. The top tube is shorter, the suspension is weight-tuned and there''s a much shorter reach to the brake
levers. All this adds up to a great mountain bike that is sure to accommodate any woman''s anatomy. In addition to getting the size right, the saddle is incredibly comfortable. 
Attention to detail is apparent in every aspect from the frame finish to the careful design of each component. Each component is a solid performer without any fluff. 
The designers clearly did their homework and thought about size, weight, and funtionality throughout. And at less than 19 pounds, the bike is manageable for even the most petite cyclist.
We had 5 riders take the bike out for a spin and really put it to the test. The results were consistent and very positive. Our testers loved the manuverability 
and control they had with the redesigned frame on the 550-W. A definite improvement over the 2012 design. Four out of five testers listed quick handling
and responsivness were the key elements they noticed. Technical climbing and on the flats, the bike just cruises through the rough. Tight corners and obstacles were handled effortlessly. The fifth tester was more impressed with the smooth ride. The heavy-duty shocks absorbed even the worst bumps and provided a soft ride on all but the 
nastiest trails and biggest drops. The shifting was rated superb and typical of what we''ve come to expect from Adventure Works Cycles. On descents, the bike handled flawlessly and tracked very well. The bike is well balanced front-to-rear and frame flex was minimal. In particular, the testers
noted that the brake system had a unique combination of power and modulation.  While some brake setups can be overly touchy, these brakes had a good
amount of power, but also a good feel that allows you to apply as little or as much braking power as is needed. Second is their short break-in period. We found that they tend to break-in well before
the end of the first ride; while others take two to three rides (or more) to come to full power. 
On the negative side, the pedals were not quite up to our tester''s standards. 
Just for fun, we experimented with routine maintenance tasks. Overall we found most operations to be straight forward and easy to complete. The only exception was replacing the front wheel. The maintenance manual that comes
with the bike say to install the front wheel with the axle quick release or bolt, then compress the fork a few times before fastening and tightening the two quick-release mechanisms on the bottom of the dropouts. This is to seat the axle in the dropouts, and if you do not
do this, the axle will become seated after you tightened the two bottom quick releases, which will then become loose. It''s better to test the tightness carefully or you may notice that the two bottom quick releases have come loose enough to fall completely open. And that''s something you don''t want to experience
while out on the road! 
The Road-550-W frame is available in a variety of sizes and colors and has the same durable, high-quality aluminum that AWC is known for. At a MSRP of just under $1125.00, it''s comparable in price to its closest competitors and
we think that after a test drive you''l find the quality and performance above and beyond . You''ll have a grin on your face and be itching to get out on the road for more. While designed for serious road racing, the Road-550-W would be an excellent choice for just about any terrain and 
any level of experience. It''s a huge step in the right direction for female cyclists and well worth your consideration and hard-earned money.', '2013-11-15 00:00:00');

SELECT 'Copying data into Production.ScrapReason';
\copy Production.ScrapReason FROM './data/ScrapReason.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.TransactionHistory';
\copy Production.TransactionHistory FROM './data/TransactionHistory.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.TransactionHistoryArchive';
\copy Production.TransactionHistoryArchive FROM './data/TransactionHistoryArchive.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.UnitMeasure';
\copy Production.UnitMeasure FROM './data/UnitMeasure.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.WorkOrder';
\copy Production.WorkOrder FROM './data/WorkOrder.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Production.WorkOrderRouting';
\copy Production.WorkOrderRouting FROM './data/WorkOrderRouting.csv' DELIMITER E'\t' CSV;

-- Calculated columns that needed to be there just for the CSV import
ALTER TABLE Production.WorkOrder DROP COLUMN StockedQty;
ALTER TABLE Production.Document DROP COLUMN DocumentLevel;

-- Document HierarchyID column
ALTER TABLE Production.Document ADD DocumentNode VARCHAR DEFAULT '/';
-- Convert from all the hex to a stream of hierarchyid bits
WITH RECURSIVE hier AS (
  SELECT rowguid, doc, get_byte(decode(substring(doc, 1, 2), 'hex'), 0)::bit(8)::varchar AS bits, 2 AS i
    FROM Production.Document
  UNION ALL
  SELECT e.rowguid, e.doc, hier.bits || get_byte(decode(substring(e.doc, i + 1, 2), 'hex'), 0)::bit(8)::varchar, i + 2 AS i
    FROM Production.Document AS e INNER JOIN
      hier ON e.rowguid = hier.rowguid AND i < LENGTH(e.doc)
)
UPDATE Production.Document AS emp
  SET doc = COALESCE(trim(trailing '0' FROM hier.bits::TEXT), '')
  FROM hier
  WHERE emp.rowguid = hier.rowguid
    AND (hier.doc IS NULL OR i = LENGTH(hier.doc));

-- Convert bits to the real hieararchy paths
CREATE OR REPLACE FUNCTION f_ConvertDocNodes()
  RETURNS void AS
$func$
DECLARE
  got_none BOOLEAN;
BEGIN
  LOOP
  got_none := true;
  -- 01 = 0-3
  UPDATE Production.Document
   SET DocumentNode = DocumentNode || SUBSTRING(doc, 3,2)::bit(2)::INTEGER::VARCHAR || CASE SUBSTRING(doc, 5, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 6, 9999)
    WHERE doc LIKE '01%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 100 = 4-7
  UPDATE Production.Document
   SET DocumentNode = DocumentNode || (SUBSTRING(doc, 4,2)::bit(2)::INTEGER + 4)::VARCHAR || CASE SUBSTRING(doc, 6, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 7, 9999)
    WHERE doc LIKE '100%';
  IF FOUND THEN
    got_none := false;
  END IF;
  
  -- 101 = 8-15
  UPDATE Production.Document
   SET DocumentNode = DocumentNode || (SUBSTRING(doc, 4,3)::bit(3)::INTEGER + 8)::VARCHAR || CASE SUBSTRING(doc, 7, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 8, 9999)
    WHERE doc LIKE '101%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 110 = 16-79
  UPDATE Production.Document
   SET DocumentNode = DocumentNode || ((SUBSTRING(doc, 4,2)||SUBSTRING(doc, 7,1)||SUBSTRING(doc, 9,3))::bit(6)::INTEGER + 16)::VARCHAR || CASE SUBSTRING(doc, 12, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 13, 9999)
    WHERE doc LIKE '110%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 1110 = 80-1103
  UPDATE Production.Document
   SET DocumentNode = DocumentNode || ((SUBSTRING(doc, 5,3)||SUBSTRING(doc, 9,3)||SUBSTRING(doc, 13,1)||SUBSTRING(doc, 15,3))::bit(10)::INTEGER + 80)::VARCHAR || CASE SUBSTRING(doc, 18, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 19, 9999)
    WHERE doc LIKE '1110%';
  IF FOUND THEN
    got_none := false;
  END IF;
  EXIT WHEN got_none;
  END LOOP;
END
$func$ LANGUAGE plpgsql;

SELECT f_ConvertDocNodes();
-- Drop the original binary hierarchyid column
ALTER TABLE Production.Document DROP COLUMN Doc;
DROP FUNCTION f_ConvertDocNodes();

-- ProductDocument HierarchyID column
  ALTER TABLE Production.ProductDocument ADD DocumentNode VARCHAR DEFAULT '/';
ALTER TABLE Production.ProductDocument ADD rowguid uuid NOT NULL CONSTRAINT "DF_ProductDocument_rowguid" DEFAULT (uuid_generate_v1());
-- Convert from all the hex to a stream of hierarchyid bits
WITH RECURSIVE hier AS (
  SELECT rowguid, doc, get_byte(decode(substring(doc, 1, 2), 'hex'), 0)::bit(8)::varchar AS bits, 2 AS i
    FROM Production.ProductDocument
  UNION ALL
  SELECT e.rowguid, e.doc, hier.bits || get_byte(decode(substring(e.doc, i + 1, 2), 'hex'), 0)::bit(8)::varchar, i + 2 AS i
    FROM Production.ProductDocument AS e INNER JOIN
      hier ON e.rowguid = hier.rowguid AND i < LENGTH(e.doc)
)
UPDATE Production.ProductDocument AS emp
  SET doc = COALESCE(trim(trailing '0' FROM hier.bits::TEXT), '')
  FROM hier
  WHERE emp.rowguid = hier.rowguid
    AND (hier.doc IS NULL OR i = LENGTH(hier.doc));

-- Convert bits to the real hieararchy paths
CREATE OR REPLACE FUNCTION f_ConvertDocNodes()
  RETURNS void AS
$func$
DECLARE
  got_none BOOLEAN;
BEGIN
  LOOP
  got_none := true;
  -- 01 = 0-3
  UPDATE Production.ProductDocument
   SET DocumentNode = DocumentNode || SUBSTRING(doc, 3,2)::bit(2)::INTEGER::VARCHAR || CASE SUBSTRING(doc, 5, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 6, 9999)
    WHERE doc LIKE '01%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 100 = 4-7
  UPDATE Production.ProductDocument
   SET DocumentNode = DocumentNode || (SUBSTRING(doc, 4,2)::bit(2)::INTEGER + 4)::VARCHAR || CASE SUBSTRING(doc, 6, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 7, 9999)
    WHERE doc LIKE '100%';
  IF FOUND THEN
    got_none := false;
  END IF;
  
  -- 101 = 8-15
  UPDATE Production.ProductDocument
   SET DocumentNode = DocumentNode || (SUBSTRING(doc, 4,3)::bit(3)::INTEGER + 8)::VARCHAR || CASE SUBSTRING(doc, 7, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 8, 9999)
    WHERE doc LIKE '101%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 110 = 16-79
  UPDATE Production.ProductDocument
   SET DocumentNode = DocumentNode || ((SUBSTRING(doc, 4,2)||SUBSTRING(doc, 7,1)||SUBSTRING(doc, 9,3))::bit(6)::INTEGER + 16)::VARCHAR || CASE SUBSTRING(doc, 12, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 13, 9999)
    WHERE doc LIKE '110%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 1110 = 80-1103
  UPDATE Production.ProductDocument
   SET DocumentNode = DocumentNode || ((SUBSTRING(doc, 5,3)||SUBSTRING(doc, 9,3)||SUBSTRING(doc, 13,1)||SUBSTRING(doc, 15,3))::bit(10)::INTEGER + 80)::VARCHAR || CASE SUBSTRING(doc, 18, 1) WHEN '0' THEN '.' ELSE '/' END,
     doc = SUBSTRING(doc, 19, 9999)
    WHERE doc LIKE '1110%';
  IF FOUND THEN
    got_none := false;
  END IF;
  EXIT WHEN got_none;
  END LOOP;
END
$func$ LANGUAGE plpgsql;

SELECT f_ConvertDocNodes();
-- Drop the original binary hierarchyid column
ALTER TABLE Production.ProductDocument DROP COLUMN Doc;
DROP FUNCTION f_ConvertDocNodes();
ALTER TABLE Production.ProductDocument DROP COLUMN rowguid;
