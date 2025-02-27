
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_birth_country, 
        c.c_current_addr_sk,
        1 AS level
    FROM customer c
    WHERE c.c_birth_country IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_birth_country, 
        c.c_current_addr_sk,
        ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 5
),
ordered_sales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_net_profit) AS total_net_profit, 
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
sales_with_ranks AS (
    SELECT 
        os.ws_item_sk,
        os.total_net_profit,
        os.order_count,
        RANK() OVER (ORDER BY os.total_net_profit DESC) AS profit_rank
    FROM ordered_sales os
)
SELECT 
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    ch.level,
    sr_item.sk AS sales_item_sk,
    COALESCE(SUM(st.ss_sales_price), 0) AS total_store_sales,
    COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales,
    CASE 
        WHEN SUM(st.ss_sales_price) > 0 THEN 'Store Sales High'
        ELSE 'Store Sales Low'
    END AS sales_comparison,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY NULLIF(SUM(ws.ws_sales_price), 0) DESC) AS state_rank
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_hierarchy ch ON c.c_customer_sk = ch.c_customer_sk
LEFT JOIN store_sales st ON c.c_customer_sk = st.ss_customer_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN sales_with_ranks sr ON sr.ws_item_sk = st.ss_item_sk
GROUP BY 
    ca.ca_address_id, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_purchase_estimate,
    ch.level,
    sales_item_sk
HAVING  
    SUM(ws.ws_net_profit) > 5000 OR ch.level > 2
ORDER BY total_web_sales DESC, total_store_sales DESC;
