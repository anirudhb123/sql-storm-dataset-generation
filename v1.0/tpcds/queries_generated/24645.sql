
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_dep_count,
        SUM(CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_net_profit ELSE 0 END) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders_count,
        CASE
            WHEN SUM(ws.ws_net_profit) > 1000 THEN 'High Spender'
            WHEN SUM(ws.ws_net_profit) BETWEEN 500 AND 1000 THEN 'Medium Spender'
            ELSE 'Low Spender'
        END AS spending_category
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_customer_id,
        cd.cd_gender,
        marital_status,
        full_name,
        cd.cd_dep_count
),
sales_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        s.s_state
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_state
),
state_comparison AS (
    SELECT 
        ss.s_state,
        SUM(ss.store_net_profit) AS total_profit,
        AVG(ss.store_net_profit) AS avg_profit_per_store
    FROM sales_summary ss
    GROUP BY ss.s_state
),
top_states AS (
    SELECT 
        sc.s_state,
        sc.total_profit
    FROM state_comparison sc
    WHERE sc.total_profit > (SELECT AVG(total_profit) FROM state_comparison)
    ORDER BY total_profit DESC
)
SELECT 
    cs.full_name,
    cs.total_web_sales,
    cs.web_orders_count,
    cs.catalog_orders_count,
    cs.spending_category,
    COALESCE(ts.total_profit, 0) AS state_profit
FROM customer_summary cs
LEFT JOIN (
    SELECT 
        c.c_customer_sk,
        ts.total_profit
    FROM top_states ts
    JOIN customer c ON c.c_current_addr_sk = 
        (SELECT ca.ca_address_sk 
         FROM customer_address ca 
         WHERE ca.ca_city = (SELECT DISTINCT ca_city 
                             FROM customer_address 
                             WHERE ca_address_sk = c.c_current_addr_sk LIMIT 1)
        )
) ts ON cs.c_customer_sk = ts.c_customer_sk
ORDER BY cs.total_web_sales DESC, cs.web_orders_count DESC
FETCH FIRST 100 ROWS ONLY;
