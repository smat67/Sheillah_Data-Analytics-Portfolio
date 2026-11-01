-- =========================================================================
-- PROJECT: E-Commerce Transaction Data Cleaning & Optimization Pipeline
-- AUTHOR: Sheillah Matsvimbo
-- TOOLS USED: SQL Server, T-SQL, Query Optimization
-- PURPOSE: Pre-processing and cleaning raw database tables before 
--          loading into Tableau to ensure 100% accurate executive KPIs.
-- =========================================================================

-- 1. DATABASE HANDLING & IDENTITY ISOLATION
-- Creating a clean development schema to isolate operational transaction rows
IF OBJECT_ID('dbo.stg_superstore_orders', 'U') IS NOT NULL
    DROP TABLE dbo.stg_superstore_orders;

CREATE TABLE dbo.stg_superstore_orders (
    Row_ID INT PRIMARY KEY,
    Order_ID NVARCHAR(50),
    Order_Date DATE,
    Ship_Date DATE,
    Customer_ID NVARCHAR(50),
    Segment NVARCHAR(50),
    Country NVARCHAR(50),
    State NVARCHAR(50),
    Sales DECIMAL(18,4),
    Profit DECIMAL(18,4)
);

-- 2. DATA TRANSFORMATION & ETL ANOMALY CORRECTION
-- Cleaning formatting inconsistencies, handling NULL values, and enforcing integrity rules
INSERT INTO dbo.stg_superstore_orders
SELECT 
    CAST([Row ID] AS INT) AS Row_ID,
    TRIM([Order ID]) AS Order_ID,
    CAST([Order Date] AS DATE) AS Order_Date,
    CAST([Ship Date] AS DATE) AS Ship_Date,
    TRIM([Customer ID]) AS Customer_ID,
    ISNULL(TRIM([Segment]), 'Consumer') AS Segment, -- Defaulting missing customer segments
    UPPER(TRIM([Country])) AS Country,               -- Standardizing text casing for mapping engines
    TRIM([State]) AS State,
    ROUND(CAST([Sales] AS DECIMAL(18,4)), 2) AS Sales,
    ROUND(CAST([Profit] AS DECIMAL(18,4)), 2) AS Profit
FROM dbo.raw_superstore_source
WHERE [Order ID] IS NOT NULL 
  AND [Sales] >= 0; -- Eliminating corrupt data records with negative revenue

-- 3. OPERATIONAL KPI GENERATION
-- Calculating precise shipping fulfillment delays for operational assistant review
SELECT 
    Order_ID,
    Order_Date,
    Ship_Date,
    DATEDIFF(day, Order_Date, Ship_Date) AS Fulfillment_Days_Delay,
    CASE 
        WHEN DATEDIFF(day, Order_Date, Ship_Date) > 4 THEN 'Fulfillment Bottleneck'
        ELSE 'Standard Logistics window'
    END AS Operational_Status
FROM dbo.stg_superstore_orders
ORDER BY Fulfillment_Days_Delay DESC;
