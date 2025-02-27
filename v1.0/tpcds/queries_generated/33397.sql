
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        total_sales > 1000
),
HighIncomeCustomers AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        MAX(hd_income_band_sk) AS max_income_band
    FROM 
        customer_demographics 
    LEFT JOIN 
        household_demographics 
    ON 
        customer_demographics.cd_demo_sk = household_demographics.hd_demo_sk 
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS web_sales_rank,
    COALESCE(hd.max_income_band, 'Unknown') AS income_band,
    CASE 
        WHEN COUNT(DISTINCT ws.ws_order_number) >= 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_category
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    HighIncomeCustomers hd ON c.c_current_cdemo_sk = hd.cd_demo_sk
WHERE 
    ca.ca_country = 'USA'
    AND c.c_birth_year > 1980
    AND (hd.max_income_band IS NULL OR hd.max_income_band IN (1, 2, 3))
GROUP BY 
    c.c_customer_id, ca.ca_city, hd.max_income_band
HAVING 
    SUM(ws.ws_ext_sales_price) > 10000
ORDER BY 
    total_web_sales DESC
LIMIT 100;

SELECT 
    sm.sm_type,
    AVG(ws.ws_net_profit) AS average_profit
FROM 
    web_sales ws
INNER JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY 
    sm.sm_type
HAVING 
    average_profit > (SELECT AVG(ws_net_profit) FROM web_sales)
ORDER BY 
    average_profit DESC
LIMIT 5;
