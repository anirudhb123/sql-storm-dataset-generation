
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
),
customer_data AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_dep_count IS NULL OR cd.cd_dep_count = 0 THEN 'No Dependents'
            ELSE 'With Dependents'
        END AS dependents_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ca.ca_state,
        SUM(r.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT r.c_customer_sk) AS distinct_customers
    FROM 
        ranked_sales r
    JOIN 
        web_sales ws ON r.ws_item_sk = ws.ws_item_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_data ca ON c.c_customer_sk = ca.c_customer_sk
    GROUP BY 
        ca.ca_state
),
aggregated_data AS (
    SELECT 
        state,
        total_net_profit,
        distinct_customers,
        RANK() OVER (ORDER BY total_net_profit DESC) AS state_rank
    FROM 
        sales_summary
)
SELECT 
    ad.state,
    ad.total_net_profit,
    ad.distinct_customers,
    d.d_year,
    CASE
        WHEN ad.total_net_profit IS NULL THEN 'No Profit'
        WHEN ad.total_net_profit < 1000 THEN 'Low Profit'
        WHEN ad.total_net_profit BETWEEN 1000 AND 5000 THEN 'Medium Profit'
        ELSE 'High Profit'
    END AS profit_category,
    EXISTS (
        SELECT 1 
        FROM store s
        WHERE s.s_city = 'Nashville' AND s.s_state = ad.state
    ) AS has_nashville_store,
    COALESCE(
        (SELECT COUNT(*) 
         FROM catalog_sales 
         WHERE cs_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk IN 
             (SELECT c_customer_sk FROM customer WHERE c_current_cdemo_sk IS NOT NULL))) 
         , 0) * 1.0 / NULLIF(ad.distinct_customers, 0) AS avg_catalog_sales_per_customer
FROM 
    aggregated_data ad
JOIN 
    date_dim d ON d.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE 
    ad.state_rank <= 10
ORDER BY 
    ad.total_net_profit DESC;
