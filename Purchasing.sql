\pset tuples_only on

-- Support to auto-generate UUIDs (aka GUIDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Support crosstab function to do PIVOT thing for Sales.vSalesPersonSalesByFiscalYears
CREATE EXTENSION tablefunc;

-------------------------------------
-- Custom data types
-------------------------------------

CREATE DOMAIN "OrderNumber" varchar(25) NULL;
CREATE DOMAIN "AccountNumber" varchar(15) NULL;

CREATE DOMAIN "Flag" boolean NOT NULL;
CREATE DOMAIN "NameStyle" boolean NOT NULL;
CREATE DOMAIN "Name" varchar(50) NULL;
CREATE DOMAIN "Phone" varchar(25) NULL;

CREATE SCHEMA Purchasing
  CREATE TABLE ProductVendor(
    ProductID INT NOT NULL,
    BusinessEntityID INT NOT NULL,
    AverageLeadTime INT NOT NULL,
    StandardPrice numeric NOT NULL, -- money
    LastReceiptCost numeric NULL, -- money
    LastReceiptDate TIMESTAMP NULL,
    MinOrderQty INT NOT NULL,
    MaxOrderQty INT NOT NULL,
    OnOrderQty INT NULL,
    UnitMeasureCode char(3) NOT NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ProductVendor_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_ProductVendor_AverageLeadTime" CHECK (AverageLeadTime >= 1),
    CONSTRAINT "CK_ProductVendor_StandardPrice" CHECK (StandardPrice > 0.00),
    CONSTRAINT "CK_ProductVendor_LastReceiptCost" CHECK (LastReceiptCost > 0.00),
    CONSTRAINT "CK_ProductVendor_MinOrderQty" CHECK (MinOrderQty >= 1),
    CONSTRAINT "CK_ProductVendor_MaxOrderQty" CHECK (MaxOrderQty >= 1),
    CONSTRAINT "CK_ProductVendor_OnOrderQty" CHECK (OnOrderQty >= 0)
  )
  CREATE TABLE PurchaseOrderDetail(
    PurchaseOrderID INT NOT NULL,
    PurchaseOrderDetailID SERIAL NOT NULL, -- int
    DueDate TIMESTAMP NOT NULL,
    OrderQty smallint NOT NULL,
    ProductID INT NOT NULL,
    UnitPrice numeric NOT NULL, -- money
    LineTotal numeric, -- AS ISNULL(OrderQty * UnitPrice, 0.00),
    ReceivedQty decimal(8, 2) NOT NULL,
    RejectedQty decimal(8, 2) NOT NULL,
    StockedQty numeric, -- AS ISNULL(ReceivedQty - RejectedQty, 0.00),
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_PurchaseOrderDetail_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_PurchaseOrderDetail_OrderQty" CHECK (OrderQty > 0),
    CONSTRAINT "CK_PurchaseOrderDetail_UnitPrice" CHECK (UnitPrice >= 0.00),
    CONSTRAINT "CK_PurchaseOrderDetail_ReceivedQty" CHECK (ReceivedQty >= 0.00),
    CONSTRAINT "CK_PurchaseOrderDetail_RejectedQty" CHECK (RejectedQty >= 0.00)
  )
  CREATE TABLE PurchaseOrderHeader(
    PurchaseOrderID SERIAL NOT NULL,  -- int
    RevisionNumber smallint NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_RevisionNumber" DEFAULT (0),  -- tinyint
    Status smallint NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_Status" DEFAULT (1),  -- tinyint
    EmployeeID INT NOT NULL,
    VendorID INT NOT NULL,
    ShipMethodID INT NOT NULL,
    OrderDate TIMESTAMP NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_OrderDate" DEFAULT (NOW()),
    ShipDate TIMESTAMP NULL,
    SubTotal numeric NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_SubTotal" DEFAULT (0.00),  -- money
    TaxAmt numeric NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_TaxAmt" DEFAULT (0.00),  -- money
    Freight numeric NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_Freight" DEFAULT (0.00),  -- money
    TotalDue numeric, -- AS ISNULL(SubTotal + TaxAmt + Freight, 0) PERSISTED NOT NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_PurchaseOrderHeader_Status" CHECK (Status BETWEEN 1 AND 4), -- 1 = Pending; 2 = Approved; 3 = Rejected; 4 = Complete
    CONSTRAINT "CK_PurchaseOrderHeader_ShipDate" CHECK ((ShipDate >= OrderDate) OR (ShipDate IS NULL)),
    CONSTRAINT "CK_PurchaseOrderHeader_SubTotal" CHECK (SubTotal >= 0.00),
    CONSTRAINT "CK_PurchaseOrderHeader_TaxAmt" CHECK (TaxAmt >= 0.00),
    CONSTRAINT "CK_PurchaseOrderHeader_Freight" CHECK (Freight >= 0.00)
  )
  CREATE TABLE ShipMethod(
    ShipMethodID SERIAL NOT NULL, -- int
    Name "Name" NOT NULL,
    ShipBase numeric NOT NULL CONSTRAINT "DF_ShipMethod_ShipBase" DEFAULT (0.00), -- money
    ShipRate numeric NOT NULL CONSTRAINT "DF_ShipMethod_ShipRate" DEFAULT (0.00), -- money
    rowguid uuid NOT NULL CONSTRAINT "DF_ShipMethod_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ShipMethod_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_ShipMethod_ShipBase" CHECK (ShipBase > 0.00),
    CONSTRAINT "CK_ShipMethod_ShipRate" CHECK (ShipRate > 0.00)
  )
  CREATE TABLE Vendor(
    BusinessEntityID INT NOT NULL,
    AccountNumber "AccountNumber" NOT NULL,
    Name "Name" NOT NULL,
    CreditRating smallint NOT NULL, -- tinyint
    PreferredVendorStatus "Flag" NOT NULL CONSTRAINT "DF_Vendor_PreferredVendorStatus" DEFAULT (true),
    ActiveFlag "Flag" NOT NULL CONSTRAINT "DF_Vendor_ActiveFlag" DEFAULT (true),
    PurchasingWebServiceURL varchar(1024) NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_Vendor_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_Vendor_CreditRating" CHECK (CreditRating BETWEEN 1 AND 5)
  );

COMMENT ON SCHEMA Purchasing IS 'Contains objects related to vendors and purchase orders.';

SELECT 'Copying data into Purchasing.ProductVendor';
\copy Purchasing.ProductVendor FROM 'ProductVendor.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Purchasing.PurchaseOrderDetail';
\copy Purchasing.PurchaseOrderDetail FROM 'PurchaseOrderDetail.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Purchasing.PurchaseOrderHeader';
\copy Purchasing.PurchaseOrderHeader FROM 'PurchaseOrderHeader.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Purchasing.ShipMethod';
\copy Purchasing.ShipMethod FROM 'ShipMethod.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Purchasing.Vendor';
\copy Purchasing.Vendor FROM 'Vendor.csv' DELIMITER E'\t' CSV;

-- Calculated columns that needed to be there just for the CSV import
ALTER TABLE Purchasing.PurchaseOrderDetail DROP COLUMN LineTotal;
ALTER TABLE Purchasing.PurchaseOrderDetail DROP COLUMN StockedQty;
ALTER TABLE Purchasing.PurchaseOrderHeader DROP COLUMN TotalDue;
