
WITH RECURSIVE AddressCTE AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM 
        customer_address 
    WHERE 
        ca_country IS NOT NULL
),
DistinctCustomers AS (
    SELECT DISTINCT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'No Dependents'
            WHEN cd.cd_dep_count = 0 THEN 'No Dependents'
            ELSE 'Has Dependents'
        END AS dependency_status
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IN ('M', 'S') 
        AND cd.cd_gender IS NOT NULL
),
SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_discount_amt,
        SUM(ws.ws_sales_price - COALESCE(ws.ws_discount_amt, 0)) AS net_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, ws.ws_sales_price, ws.ws_discount_amt
    HAVING 
        SUM(ws.ws_sales_price) > 100
)
SELECT 
    ac.ca_city,
    ac.ca_state,
    dc.c_customer_id,
    dc.dependency_status,
    COALESCE(SUM(sd.net_sales), 0) AS total_sales,
    COUNT(sd.ws_order_number) AS order_count,
    CASE 
        WHEN COUNT(sd.ws_order_number) > 0 THEN MAX(sd.rank_sales)
        ELSE NULL
    END AS highest_order_rank,
    COUNT(DISTINCT ac.ca_country) AS unique_countries
FROM 
    AddressCTE ac
    JOIN DistinctCustomers dc ON dc.cd_income_band_sk IS NOT NULL
    LEFT JOIN SalesData sd ON sd.ws_order_number IN (
        SELECT ws_order_number 
        FROM web_sales WHERE ws_bill_customer_sk IS NOT NULL
    )
GROUP BY 
    ac.ca_city, ac.ca_state, dc.c_customer_id, dc.dependency_status
HAVING 
    COUNT(dc.c_customer_id) > 1 
    AND SUM(COALESCE(sd.net_sales, 0)) >= 500
ORDER BY 
    unique_countries DESC, total_sales DESC
LIMIT 10;
