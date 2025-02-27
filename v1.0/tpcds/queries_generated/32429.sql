
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_manager,
        1 AS level
    FROM store
    WHERE s_closed_date_sk IS NULL

    UNION ALL

    SELECT 
        s.store_sk,
        sh.s_store_name,
        sh.s_number_employees,
        sh.s_floor_space,
        sh.s_manager,
        level + 1
    FROM sales_hierarchy sh
    JOIN store s ON sh.s_manager = s.s_manager
    WHERE sh.level < 5
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, cd.cd_gender
),
profit_ranked AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
    FROM customer_data
),
filtered_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0
    GROUP BY ws.ws_item_sk
),
null_check AS (
    SELECT 
        ca.ca_address_id,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_id
    HAVING COUNT(c.c_customer_sk) IS NULL
)
SELECT 
    sh.s_store_name,
    COUNT(DISTINCT cr.resolved_customer_id) AS resolved_customer,
    SUM(f.total_sales) AS total_sales,
    SUM(f.net_profit) AS net_profit,
    n.customer_count AS null_address_count
FROM sales_hierarchy sh
LEFT JOIN filtered_sales f ON sh.s_store_sk = f.ws_item_sk
LEFT JOIN null_check n ON TRUE AND n.customer_count > 0
LEFT JOIN profit_ranked pr ON sh.s_store_sk = pr.c_customer_sk 
WHERE pr.profit_rank <= 10
GROUP BY sh.s_store_name, n.customer_count
ORDER BY total_sales DESC;
