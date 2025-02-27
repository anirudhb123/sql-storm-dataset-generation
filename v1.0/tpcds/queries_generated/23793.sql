
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_dep_count DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IS NOT NULL
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CASE WHEN ca.ca_country IS NULL THEN 'Unknown Country' ELSE ca.ca_country END AS country_desc
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('NY', 'CA', 'TX')
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459300 AND 2459305  -- Simulated date range
    GROUP BY 
        ws.ws_item_sk
),
final_summary AS (
    SELECT 
        ch.c_first_name,
        ch.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.country_desc,
        ss.total_profit,
        ss.order_count,
        ss.avg_sales_price,
        CASE 
            WHEN ss.total_profit IS NULL THEN 'No Sales'
            WHEN ss.total_profit = 0 THEN 'Break-even'
            ELSE 'Profitable'
        END AS profitability_status
    FROM 
        customer_hierarchy ch
    LEFT JOIN 
        customer_addresses ca ON ch.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        sales_summary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    *,
    RANK() OVER (PARTITION BY profitability_status ORDER BY total_profit DESC) AS rank_within_status
FROM 
    final_summary
WHERE 
    profitability_status <> 'No Sales'
ORDER BY 
    profitability_status, total_profit DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM final_summary WHERE profitability_status = 'Profitable') / 2;
