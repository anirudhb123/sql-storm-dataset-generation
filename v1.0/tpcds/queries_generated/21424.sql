
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM store_sales
    GROUP BY ss_store_sk
),
top_stores AS (
    SELECT 
        sh.ss_store_sk,
        sh.total_net_profit,
        st.s_store_name,
        st.s_city,
        st.s_state
    FROM sales_hierarchy sh
    JOIN store st ON sh.ss_store_sk = st.s_store_sk
    WHERE sh.rank <= 10
),
item_sales AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        (SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS cumulative_sales,
        CASE WHEN SUM(ws.ws_quantity) > 100 THEN 'High Volume' ELSE 'Low Volume' END AS sales_category
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE ws.ws_sold_date_sk IN (SELECT DISTINCT d_date_sk FROM date_dim WHERE d_year = 2023)
),
customer_summary AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_city
    ORDER BY customer_count DESC
)
SELECT 
    ts.s_store_name,
    ts.total_net_profit,
    ts.s_city,
    ts.s_state,
    is.i_product_name,
    is.cumulative_sales,
    cs.customer_count,
    cs.avg_purchase_estimate
FROM top_stores ts
LEFT JOIN item_sales is ON ts.ss_store_sk = is.i_item_sk
JOIN customer_summary cs ON ts.s_city = cs.ca_city
WHERE ts.total_net_profit IS NOT NULL
AND (cs.customer_count >= COALESCE(NULLIF(ts.total_net_profit, 0), 1) / 1000)
ORDER BY ts.total_net_profit DESC, ts.s_store_name ASC;
