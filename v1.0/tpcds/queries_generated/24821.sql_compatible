
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_customer_id, 
           c_first_name, c_last_name,
           c_current_cdemo_sk,
           1 AS depth
    FROM customer
    WHERE c_customer_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_customer_id, 
           c.c_first_name, c.c_last_name,
           c.c_current_cdemo_sk,
           ch.depth + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk 
    WHERE ch.depth < 10
),
order_summary AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        MAX(cs_sales_price) AS max_sales_price,
        COUNT(DISTINCT cs_item_sk) FILTER (WHERE cs_sales_price < 50) AS cheap_items_count
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
),
customer_summary AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_customer_id,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(os.total_net_paid, 0) AS total_net_paid,
        COALESCE(os.total_orders, 0) AS total_orders,
        os.max_sales_price,
        os.cheap_items_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY total_net_paid DESC) AS gender_rank
    FROM customer_hierarchy ch
    LEFT JOIN customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN order_summary os ON ch.c_customer_sk = os.cs_bill_customer_sk
),
active_customers AS (
    SELECT 
        cs.cs_bill_customer_sk, 
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    WHERE ws.ws_ship_date_sk IS NOT NULL
    GROUP BY cs.cs_bill_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    NULLIF(cs.max_sales_price, 0) / NULLIF(cs.cheap_items_count, 0) AS average_price_of_cheap_items,
    ac.total_sales,
    ac.order_count,
    CASE 
        WHEN cs.gender_rank <= 10 THEN 'Top 10 by Gender'
        ELSE 'Others'
    END AS category
FROM customer_summary cs
LEFT JOIN active_customers ac ON cs.c_customer_sk = ac.cs_bill_customer_sk
WHERE cs.total_net_paid > (SELECT AVG(total_net_paid) FROM customer_summary) 
  AND cs.total_orders > 1
ORDER BY average_price_of_cheap_items DESC
LIMIT 100;
