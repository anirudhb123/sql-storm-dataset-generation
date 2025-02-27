
WITH SalesSummary AS (
    SELECT 
        d.d_year AS SalesYear,
        SUM(CASE WHEN ws_double.drug_type = 'prescription' THEN ws_ext_sales_price ELSE 0 END) AS TotalPrescriptionSales,
        SUM(CASE WHEN ws_double.drug_type = 'over_the_counter' THEN ws_ext_sales_price ELSE 0 END) AS TotalOTCSales,
        COUNT(DISTINCT ws.bill_customer_sk) AS UniqueCustomers
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        (SELECT i_item_sk, 'prescription' AS drug_type FROM item WHERE i_category = 'Prescription Drugs'
     UNION ALL
     SELECT i_item_sk, 'over_the_counter' AS drug_type FROM item WHERE i_category = 'Over The Counter Drugs') AS ws_double
    ON 
        i.i_item_sk = ws_double.i_item_sk
    GROUP BY 
        d.d_year
)
SELECT 
    SalesYear,
    TotalPrescriptionSales,
    TotalOTCSales,
    UniqueCustomers,
    (TotalPrescriptionSales + TotalOTCSales) / NULLIF(UniqueCustomers, 0) AS AverageSalesPerCustomer
FROM 
    SalesSummary
ORDER BY 
    SalesYear DESC;
