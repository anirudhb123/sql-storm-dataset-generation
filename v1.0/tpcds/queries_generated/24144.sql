
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws.web_site_sk,
        ws.web_sales_price,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
),
Null_Handled_Sales AS (
    SELECT
        web_site_sk,
        COALESCE(SUM(ws_sales_price), 0) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM Sales_CTE
    GROUP BY web_site_sk
),
Income_Band_Info AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(d.cd_purchase_estimate) AS average_purchase
    FROM household_demographics h
    LEFT JOIN customer_demographics d ON h.hd_demo_sk = d.cd_demo_sk
    WHERE h.hd_buy_potential IS NOT NULL
    GROUP BY h.hd_income_band_sk
)
SELECT 
    a.ca_state,
    COALESCE(s.total_sales, 0) AS total_web_sales,
    COALESCE(i.customer_count, 0) AS total_customers,
    CASE
        WHEN i.average_purchase IS NULL THEN 'No Data'
        ELSE CONCAT('$', ROUND(i.average_purchase, 2))
    END AS avg_purchase_per_customer
FROM customer_address a
LEFT JOIN Null_Handled_Sales s ON s.web_site_sk = a.ca_address_sk
LEFT JOIN Income_Band_Info i ON i.hd_income_band_sk = (SELECT DISTINCT hd_income_band_sk FROM household_demographics WHERE hd_demo_sk IN (SELECT c_current_hdemo_sk FROM customer WHERE c_current_addr_sk = a.ca_address_sk))
WHERE a.ca_country IS NOT NULL
    AND (EXISTS (SELECT 1 FROM customer c WHERE c.c_current_addr_sk = a.ca_address_sk) OR NOT EXISTS (SELECT 1 FROM customer c WHERE c.c_current_addr_sk = a.ca_address_sk))
ORDER BY a.ca_state
LIMIT 50 OFFSET 10;
