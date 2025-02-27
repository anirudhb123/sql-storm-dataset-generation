
WITH RegionalDemographics AS (
    SELECT 
        ca_state AS State,
        cd_gender AS Gender,
        COUNT(DISTINCT c_customer_sk) AS CustomerCount,
        AVG(cd_purchase_estimate) AS AvgPurchaseEstimate,
        AVG(cd_dep_count) AS AvgDependentCount,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS MaritalStatuses
    FROM 
        customer_address
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        ca_state, cd_gender
),
SalesPerformance AS (
    SELECT 
        w.w_warehouse_name AS Warehouse,
        SUM(CASE WHEN ws_sold_date_sk IS NOT NULL THEN ws_quantity ELSE 0 END) AS TotalWebSales,
        SUM(CASE WHEN cs_sold_date_sk IS NOT NULL THEN cs_quantity ELSE 0 END) AS TotalCatalogSales,
        SUM(CASE WHEN ss_sold_date_sk IS NOT NULL THEN ss_quantity ELSE 0 END) AS TotalStoreSales
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN 
        catalog_sales cs ON w.w_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        w.warehouse_name
),
CombinedData AS (
    SELECT 
        rd.State,
        rd.Gender,
        rd.CustomerCount,
        rd.AvgPurchaseEstimate,
        rd.AvgDependentCount,
        rd.MaritalStatuses,
        sp.Warehouse,
        sp.TotalWebSales,
        sp.TotalCatalogSales,
        sp.TotalStoreSales
    FROM 
        RegionalDemographics rd
    LEFT JOIN 
        SalesPerformance sp ON rd.State = ARRAY(SELECT DISTINCT ca_state FROM customer_address)
)
SELECT 
    State,
    Gender,
    CustomerCount,
    AvgPurchaseEstimate,
    AvgDependentCount,
    MaritalStatuses,
    Warehouse,
    TotalWebSales,
    TotalCatalogSales,
    TotalStoreSales
FROM 
    CombinedData
ORDER BY 
    State, Gender;
