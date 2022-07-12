pset tuples_only on

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

  CREATE TABLE Department(
    DepartmentID SERIAL NOT NULL, -- smallint
    Name "Name" NOT NULL,
    GroupName "Name" NOT NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_Department_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE Employee(
    BusinessEntityID INT NOT NULL,
    NationalIDNumber varchar(15) NOT NULL,
    LoginID varchar(256) NOT NULL,    
    Org varchar NULL,-- hierarchyid, will become OrganizationNode
    OrganizationLevel INT NULL, -- AS OrganizationNode.GetLevel(),
    JobTitle varchar(50) NOT NULL,
    BirthDate DATE NOT NULL,
    MaritalStatus char(1) NOT NULL,
    Gender char(1) NOT NULL,
    HireDate DATE NOT NULL,
    SalariedFlag "Flag" NOT NULL CONSTRAINT "DF_Employee_SalariedFlag" DEFAULT (true),
    VacationHours smallint NOT NULL CONSTRAINT "DF_Employee_VacationHours" DEFAULT (0),
    SickLeaveHours smallint NOT NULL CONSTRAINT "DF_Employee_SickLeaveHours" DEFAULT (0),
    CurrentFlag "Flag" NOT NULL CONSTRAINT "DF_Employee_CurrentFlag" DEFAULT (true),
    rowguid uuid NOT NULL CONSTRAINT "DF_Employee_rowguid" DEFAULT (uuid_generate_v1()), -- ROWGUIDCOL
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_Employee_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_Employee_BirthDate" CHECK (BirthDate BETWEEN '1930-01-01' AND NOW() - INTERVAL '18 years'),
    CONSTRAINT "CK_Employee_MaritalStatus" CHECK (UPPER(MaritalStatus) IN ('M', 'S')), -- Married or Single
    CONSTRAINT "CK_Employee_HireDate" CHECK (HireDate BETWEEN '1996-07-01' AND NOW() + INTERVAL '1 day'),
    CONSTRAINT "CK_Employee_Gender" CHECK (UPPER(Gender) IN ('M', 'F')), -- Male or Female
    CONSTRAINT "CK_Employee_VacationHours" CHECK (VacationHours BETWEEN -40 AND 240),
    CONSTRAINT "CK_Employee_SickLeaveHours" CHECK (SickLeaveHours BETWEEN 0 AND 120)
  )
  CREATE TABLE EmployeeDepartmentHistory(
    BusinessEntityID INT NOT NULL,
    DepartmentID smallint NOT NULL,
    ShiftID smallint NOT NULL, -- tinyint
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_EmployeeDepartmentHistory_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_EmployeeDepartmentHistory_EndDate" CHECK ((EndDate >= StartDate) OR (EndDate IS NULL))
  )
  CREATE TABLE EmployeePayHistory(
    BusinessEntityID INT NOT NULL,
    RateChangeDate TIMESTAMP NOT NULL,
    Rate numeric NOT NULL, -- money
    PayFrequency smallint NOT NULL,  -- tinyint
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_EmployeePayHistory_ModifiedDate" DEFAULT (NOW()),
    CONSTRAINT "CK_EmployeePayHistory_PayFrequency" CHECK (PayFrequency IN (1, 2)), -- 1 = monthly salary, 2 = biweekly salary
    CONSTRAINT "CK_EmployeePayHistory_Rate" CHECK (Rate BETWEEN 6.50 AND 200.00)
  )
  CREATE TABLE JobCandidate(
    JobCandidateID SERIAL NOT NULL, -- int
    BusinessEntityID INT NULL,
    Resume XML NULL, -- XML(HRResumeSchemaCollection)
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_JobCandidate_ModifiedDate" DEFAULT (NOW())
  )
  CREATE TABLE Shift(
    ShiftID SERIAL NOT NULL, -- tinyint
    Name "Name" NOT NULL,
    StartTime time NOT NULL,
    EndTime time NOT NULL,
    ModifiedDate TIMESTAMP NOT NULL CONSTRAINT "DF_Shift_ModifiedDate" DEFAULT (NOW())
  );

COMMENT ON SCHEMA HumanResources IS 'Contains objects related to employees and departments.';

SELECT 'Copying data into HumanResources.Department';
\copy HumanResources.Department FROM './data/Department.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into HumanResources.Employee';
\copy HumanResources.Employee FROM './data/Employee.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into HumanResources.EmployeeDepartmentHistory';
\copy HumanResources.EmployeeDepartmentHistory FROM './data/EmployeeDepartmentHistory.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into HumanResources.EmployeePayHistory';
\copy HumanResources.EmployeePayHistory FROM './data/EmployeePayHistory.csv' DELIMITER E'\t' CSV;
SELECT 'Copying data into HumanResources.JobCandidate';
\copy HumanResources.JobCandidate FROM './data/JobCandidate.csv' DELIMITER E'\t' CSV ENCODING 'latin1';
SELECT 'Copying data into HumanResources.Shift';
\copy HumanResources.Shift FROM './data/Shift.csv' DELIMITER E'\t' CSV;

-- Calculated column that needed to be there just for the CSV import
ALTER TABLE HumanResources.Employee DROP COLUMN OrganizationLevel;

-- Employee HierarchyID column
ALTER TABLE HumanResources.Employee ADD organizationnode VARCHAR DEFAULT '/';
-- Convert from all the hex to a stream of hierarchyid bits
WITH RECURSIVE hier AS (
  SELECT businessentityid, org, get_byte(decode(substring(org, 1, 2), 'hex'), 0)::bit(8)::varchar AS bits, 2 AS i
    FROM HumanResources.Employee
  UNION ALL
  SELECT e.businessentityid, e.org, hier.bits || get_byte(decode(substring(e.org, i + 1, 2), 'hex'), 0)::bit(8)::varchar, i + 2 AS i
    FROM HumanResources.Employee AS e INNER JOIN
      hier ON e.businessentityid = hier.businessentityid AND i < LENGTH(e.org)
)
UPDATE HumanResources.Employee AS emp
  SET org = COALESCE(trim(trailing '0' FROM hier.bits::TEXT), '')
  FROM hier
  WHERE emp.businessentityid = hier.businessentityid
    AND (hier.org IS NULL OR i = LENGTH(hier.org));

-- Convert bits to the real hieararchy paths
CREATE OR REPLACE FUNCTION f_ConvertOrgNodes()
  RETURNS void AS
$func$
DECLARE
  got_none BOOLEAN;
BEGIN
  LOOP
  got_none := true;
  -- 01 = 0-3
  UPDATE HumanResources.Employee
   SET organizationnode = organizationnode || SUBSTRING(org, 3,2)::bit(2)::INTEGER::VARCHAR || CASE SUBSTRING(org, 5, 1) WHEN '0' THEN '.' ELSE '/' END,
     org = SUBSTRING(org, 6, 9999)
    WHERE org LIKE '01%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 100 = 4-7
  UPDATE HumanResources.Employee
   SET organizationnode = organizationnode || (SUBSTRING(org, 4,2)::bit(2)::INTEGER + 4)::VARCHAR || CASE SUBSTRING(org, 6, 1) WHEN '0' THEN '.' ELSE '/' END,
     org = SUBSTRING(org, 7, 9999)
    WHERE org LIKE '100%';
  IF FOUND THEN
    got_none := false;
  END IF;
  
  -- 101 = 8-15
  UPDATE HumanResources.Employee
   SET organizationnode = organizationnode || (SUBSTRING(org, 4,3)::bit(3)::INTEGER + 8)::VARCHAR || CASE SUBSTRING(org, 7, 1) WHEN '0' THEN '.' ELSE '/' END,
     org = SUBSTRING(org, 8, 9999)
    WHERE org LIKE '101%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 110 = 16-79
  UPDATE HumanResources.Employee
   SET organizationnode = organizationnode || ((SUBSTRING(org, 4,2)||SUBSTRING(org, 7,1)||SUBSTRING(org, 9,3))::bit(6)::INTEGER + 16)::VARCHAR || CASE SUBSTRING(org, 12, 1) WHEN '0' THEN '.' ELSE '/' END,
     org = SUBSTRING(org, 13, 9999)
    WHERE org LIKE '110%';
  IF FOUND THEN
    got_none := false;
  END IF;

  -- 1110 = 80-1103
  UPDATE HumanResources.Employee
   SET organizationnode = organizationnode || ((SUBSTRING(org, 5,3)||SUBSTRING(org, 9,3)||SUBSTRING(org, 13,1)||SUBSTRING(org, 15,3))::bit(10)::INTEGER + 80)::VARCHAR || CASE SUBSTRING(org, 18, 1) WHEN '0' THEN '.' ELSE '/' END,
     org = SUBSTRING(org, 19, 9999)
    WHERE org LIKE '1110%';
  IF FOUND THEN
    got_none := false;
  END IF;
  EXIT WHEN got_none;
  END LOOP;
END
$func$ LANGUAGE plpgsql;

SELECT f_ConvertOrgNodes();
-- Drop the original binary hierarchyid column
ALTER TABLE HumanResources.Employee DROP COLUMN Org;
DROP FUNCTION f_ConvertOrgNodes();
