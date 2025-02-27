
WITH RECURSIVE AddressHierarchy AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state, 
        ca_country, 
        ca_street_name 
    FROM 
        customer_address 
    WHERE 
        ca_country IS NOT NULL
    UNION ALL
    SELECT 
        a.ca_address_sk, 
        a.ca_city, 
        a.ca_state, 
        a.ca_country, 
        CONCAT(h.ca_street_name, ' & ', a.ca_street_name) 
    FROM 
        customer_address a
    JOIN 
        AddressHierarchy h ON a.ca_address_sk = h.ca_address_sk + 1
    WHERE 
        a.ca_state = h.ca_state OR a.ca_country = h.ca_country
),
IncomeGroup AS (
    SELECT 
        hd_demo_sk, 
        CASE 
            WHEN hd_income_band_sk IS NULL THEN 'Unknown' 
            WHEN hd_income_band_sk BETWEEN 1 AND 3 THEN 'Low' 
            WHEN hd_income_band_sk BETWEEN 4 AND 6 THEN 'Medium' 
            WHEN hd_income_band_sk BETWEEN 7 AND 10 THEN 'High' 
            ELSE 'Out of Range' 
        END AS income_band 
    FROM 
        household_demographics
),
SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales, 
        SUM(ws_net_profit) AS total_profit 
    FROM 
        web_sales 
    WHERE 
        (ws_quantity IS NOT NULL AND ws_net_profit IS NOT NULL)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_sales, 
        sd.total_profit, 
        RANK() OVER (PARTITION BY sd.ws_sold_date_sk ORDER BY sd.total_sales DESC) AS sales_rank 
    FROM 
        SalesData sd
)
SELECT 
    a.ca_city, 
    a.ca_state, 
    i.income_band, 
    ts.total_sales, 
    ts.total_profit 
FROM 
    AddressHierarchy a 
LEFT JOIN 
    IncomeGroup i ON a.ca_address_sk = i.hd_demo_sk 
JOIN 
    TopSales ts ON a.ca_address_sk = ts.ws_item_sk 
WHERE 
    ts.sales_rank <= 10 
    AND (a.ca_state = 'CA' OR a.ca_country = 'USA') 
    AND (i.income_band <> 'Unknown' AND i.income_band IS NOT NULL) 
ORDER BY 
    ts.total_profit DESC NULLS LAST;
