
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           c.c_first_name, 
           c.c_last_name, 
           c.c_preferred_cust_flag, 
           CAST(c.c_first_name AS VARCHAR(50)) AS customer_full_name,
           1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL

    UNION ALL 

    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           c.c_first_name, 
           c.c_last_name, 
           c.c_preferred_cust_flag, 
           ch.customer_full_name || ' -> ' || c.c_first_name AS customer_full_name,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON ch.c_customer_sk = c.c_current_hdemo_sk
    WHERE ch.level < 5
),
seasonal_sales AS (
    SELECT 
        EXTRACT(MONTH FROM d.d_date) AS sale_month, 
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY sale_month
),
state_sales AS (
    SELECT 
        ca.ca_state, 
        SUM(ss.ss_net_paid) AS state_total_sales
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
)
SELECT 
    ch.customer_full_name,
    ss.sale_month,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_sales, 0) / NULLIF(SUM(ss.total_sales) OVER(), 0) AS sales_ratio,
    st.ca_state,
    SUM(COALESCE(st.state_total_sales, 0)) AS total_state_sales
FROM customer_hierarchy ch
LEFT JOIN seasonal_sales ss ON ss.sale_month = EXTRACT(MONTH FROM CURRENT_DATE)
LEFT JOIN state_sales st ON TRUE -- Global join, might change this to a specific filter
WHERE LOWER(ch.c_last_name) LIKE 'a%' 
GROUP BY ch.customer_full_name, ss.sale_month, st.ca_state
ORDER BY total_sales DESC, total_state_sales DESC
LIMIT 10;
