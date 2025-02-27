
WITH RECURSIVE income_distribution AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        ROW_NUMBER() OVER (ORDER BY ib_lower_bound) AS income_rank
    FROM 
        income_band
), 
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN' 
            ELSE 
                CASE 
                    WHEN cd.cd_purchase_estimate < 5000 THEN 'LOW'
                    WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 15000 THEN 'MEDIUM'
                    ELSE 'HIGH' 
                END 
        END AS purchase_category
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        MAX(ws_sales_price) AS max_sale,
        MIN(ws_sales_price) AS min_sale
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
joined_data AS (
    SELECT 
        ci.c_customer_sk,
        ci.ca_city,
        ci.ca_state,
        ss.total_profit,
        ss.total_orders,
        ss.max_sale,
        ss.min_sale,
        id.ib_lower_bound,
        id.ib_upper_bound,
        id.income_rank
    FROM 
        customer_info ci
    LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN income_distribution id ON ci.cd_purchase_estimate BETWEEN id.ib_lower_bound AND id.ib_upper_bound
)

SELECT 
    jd.*,
    ROW_NUMBER() OVER (PARTITION BY jd.income_rank ORDER BY jd.total_profit DESC) AS rank_within_income,
    CASE 
        WHEN jd.total_orders IS NULL THEN 'NO ORDERS'
        WHEN jd.total_orders = 0 THEN 'ZERO ORDERS'
        ELSE CAST(jd.max_sale / NULLIF(jd.total_orders, 0) AS DECIMAL(10, 2)) 
    END AS avg_sale_per_order
FROM 
    joined_data jd
WHERE 
    jd.ca_state IS NOT NULL
    AND jd.total_profit > (SELECT AVG(total_profit) FROM sales_summary)
ORDER BY 
    jd.income_rank, 
    jd.total_profit DESC;
