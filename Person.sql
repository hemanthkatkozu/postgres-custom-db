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

CREATE SCHEMA Person
  CREATE TABLE BusinessEntity(
    BusinessEntityID SERIAL, --  NOT FOR REPLICATION
    rowguid uuid NOT NULL CONSTRAINT "DF_BusinessEntity_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_BusinessEntity_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE Person(
    BusinessEntityID INT NOT NULL,
    PersonType char(2) NOT NULL,
    NameStyle "NameStyle" NOT NULL CONSTRAINT "DF_Person_NameStyle" DEFAULT (false),
    Title varchar(8) NULL,
    FirstName "Name" NOT NULL,
    MiddleName "Name" NULL,
    LastName "Name" NOT NULL,
    Suffix varchar(10) NULL,
    EmailPromotion INT NOT NULL CONSTRAINT "DF_Person_EmailPromotion" DEFAULT (0),
    AdditionalContactInfo XML NULL, -- XML("AdditionalContactInfoSchemaCollection"),
    Demographics XML NULL, -- XML("IndividualSurveySchemaCollection"),
    rowguid uuid NOT NULL CONSTRAINT "DF_Person_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_Person_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_Person_EmailPromotion" CHECK (EmailPromotion BETWEEN 0 AND 2),
    CONSTRAINT "CK_Person_PersonType" CHECK (PersonType IS NULL OR UPPER(PersonType) IN ('SC', 'VC', 'IN', 'EM', 'SP', 'GC'))
  )
  CREATE TABLE StateProvince(
    StateProvinceID SERIAL,
    StateProvinceCode char(3) NOT NULL,
    CountryRegionCode varchar(3) NOT NULL,
    IsOnlyStateProvinceFlag "Flag" NOT NULL CONSTRAINT "DF_StateProvince_IsOnlyStateProvinceFlag" DEFAULT (true),
    Name "Name" NOT NULL,
    TerritoryID INT NOT NULL,
    rowguid uuid NOT NULL CONSTRAINT "DF_StateProvince_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_StateProvince_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE Address(
    AddressID SERIAL, --  NOT FOR REPLICATION
    AddressLine1 varchar(60) NOT NULL,
    AddressLine2 varchar(60) NULL,
    City varchar(30) NOT NULL,
    StateProvinceID INT NOT NULL,
    PostalCode varchar(15) NOT NULL,
    SpatialLocation varchar(44) NULL,
    rowguid uuid NOT NULL CONSTRAINT "DF_Address_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_Address_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE AddressType(
    AddressTypeID SERIAL,
    Name "Name" NOT NULL,
    rowguid uuid NOT NULL CONSTRAINT "DF_AddressType_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_AddressType_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE BusinessEntityAddress(
    BusinessEntityID INT NOT NULL,
    AddressID INT NOT NULL,
    AddressTypeID INT NOT NULL,
    rowguid uuid NOT NULL CONSTRAINT "DF_BusinessEntityAddress_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_BusinessEntityAddress_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE ContactType(
    ContactTypeID SERIAL,
    Name "Name" NOT NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_ContactType_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE BusinessEntityContact(
    BusinessEntityID INT NOT NULL,
    PersonID INT NOT NULL,
    ContactTypeID INT NOT NULL,
    rowguid uuid NOT NULL CONSTRAINT "DF_BusinessEntityContact_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_BusinessEntityContact_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE EmailAddress(
    BusinessEntityID INT NOT NULL,
    EmailAddressID SERIAL,
    EmailAddress varchar(50) NULL,
    rowguid uuid NOT NULL CONSTRAINT "DF_EmailAddress_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_EmailAddress_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE Password(
    BusinessEntityID INT NOT NULL,
    PasswordHash VARCHAR(128) NOT NULL,
    PasswordSalt VARCHAR(10) NOT NULL,
    rowguid uuid NOT NULL CONSTRAINT "DF_Password_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_Password_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE PhoneNumberType(
    PhoneNumberTypeID SERIAL,
    Name "Name" NOT NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_PhoneNumberType_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE PersonPhone(
    BusinessEntityID INT NOT NULL,
    PhoneNumber "Phone" NOT NULL,
    PhoneNumberTypeID INT NOT NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_PersonPhone_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE CountryRegion(
    CountryRegionCode varchar(3) NOT NULL,
    Name "Name" NOT NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_CountryRegion_ModifiedDate" DEFAULT (NOW())
  );

COMMENT ON SCHEMA Person IS 'Contains objects related to names and addresses of customers, vendors, and employees';

SELECT 'Copying data into Person.BusinessEntity';
\copy Person.BusinessEntity FROM './data/BusinessEntity.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Person.Person';
\copy Person.Person FROM './data/Person.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Person.StateProvince';
\copy Person.StateProvince FROM './data/StateProvince.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Person.Address';
\copy Person.Address FROM './data/Address.csv' DELIMITER E'\t' CSV ENCODING 'latin1';
SELECT 'Copying data into Person.AddressType';
\copy Person.AddressType FROM './data/AddressType.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Person.BusinessEntityAddress';
\copy Person.BusinessEntityAddress FROM './data/BusinessEntityAddress.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Person.ContactType';
\copy Person.ContactType FROM './data/ContactType.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Person.BusinessEntityContact';
\copy Person.BusinessEntityContact FROM './data/BusinessEntityContact.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Person.EmailAddress';
\copy Person.EmailAddress FROM './data/EmailAddress.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Person.Password';
\copy Person.Password FROM './data/Password.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Person.PhoneNumberType';
\copy Person.PhoneNumberType FROM './data/PhoneNumberType.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Person.PersonPhone';
\copy Person.PersonPhone FROM './data/PersonPhone.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into Person.CountryRegion';
\copy Person.CountryRegion FROM './data/CountryRegion.csv' DELIMITER E'\t' CSV;
