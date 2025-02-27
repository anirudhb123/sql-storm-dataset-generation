
WITH RECURSIVE demographic_analysis AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_rank
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
),
address_ranked AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM customer_address 
    WHERE ca_city IS NOT NULL
),
date_sales AS (
    SELECT 
        d.d_date,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        LAG(SUM(ws.ws_net_profit)) OVER (ORDER BY d.d_date) AS previous_profit
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
),
sales_trends AS (
    SELECT 
        d.d_date,
        total_sales,
        total_profit,
        total_quantity,
        CASE 
            WHEN total_profit > previous_profit THEN 'Increase'
            WHEN total_profit < previous_profit THEN 'Decrease'
            ELSE 'No Change'
        END AS profit_trend
    FROM date_sales d
)
SELECT 
    da.gender,
    da.marital_status,
    da.purchase_estimate,
    ar.city_rank,
    ar.ca_city,
    ar.ca_state,
    ds.d_date,
    ds.total_sales,
    ds.total_profit,
    ds.profit_trend
FROM demographic_analysis da
FULL OUTER JOIN address_ranked ar ON da.cd_demo_sk = ar.ca_address_sk
FULL OUTER JOIN sales_trends ds ON da.cd_demo_sk = (SELECT MIN(cd_demo_sk) FROM customer WHERE c_current_addr_sk IS NOT NULL)
WHERE 
    da.gender_rank <= 5 
    OR ar.city_rank <= 5
    OR ds.total_sales > 1000
    OR da.cd_credit_rating IS NULL
ORDER BY 
    ds.d_date DESC, 
    da.purchase_estimate DESC NULLS FIRST,
    ar.city_rank;
