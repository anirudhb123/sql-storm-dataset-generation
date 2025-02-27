
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
),
TotalReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned_qty,
        SUM(cr_return_amt) AS total_returned_amt
    FROM catalog_returns
    GROUP BY cr_item_sk
),
DateAnalysis AS (
    SELECT 
        d_year,
        COUNT(*) AS total_sales,
        SUM(ws_sales_price) AS total_sales_amt
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY d_year
),
DemographicDetails AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(CASE WHEN cd_purchase_estimate > 2000 THEN 1 ELSE 0 END) AS high_value_customers
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
)
SELECT 
    ca.ca_country,
    dd.d_year,
    COALESCE(rp.high_value_customers, 0) AS high_value_count,
    COALESCE(TR.total_returned_qty, 0) AS total_returned_qty,
    COALESCE(TR.total_returned_amt, 0) AS total_returned_amt,
    SUM(RS.ws_sales_price) AS total_sales_price
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN RankedSales RS ON c.c_customer_sk = RS.ws_item_sk
JOIN DateAnalysis dd ON dd.total_sales > 0
LEFT JOIN TotalReturns TR ON RS.ws_item_sk = TR.cr_item_sk
LEFT JOIN DemographicDetails rp ON c.c_customer_sk = rp.high_value_customers
WHERE 
    (TR.total_returned_qty IS NULL OR TR.total_returned_qty < 10)
    AND dd.d_year BETWEEN 2020 AND 2022
    AND (ca.ca_country = 'USA' OR ca.ca_country IS NULL)
GROUP BY 
    ca.ca_country, 
    dd.d_year, 
    rp.high_value_customers
HAVING 
    SUM(RS.ws_sales_price) > 10000
ORDER BY 
    ca.ca_country, 
    dd.d_year DESC;
