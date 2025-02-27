
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk, 
        COUNT(ss_ticket_number) AS total_sales,
        SUM(ss_net_paid) AS total_revenue,
        1 AS level
    FROM store_sales
    GROUP BY ss_store_sk
    UNION ALL
    SELECT 
        ss.ss_store_sk,
        sh.total_sales + COUNT(ss.ss_ticket_number),
        sh.total_revenue + SUM(ss.ss_net_paid),
        sh.level + 1
    FROM store_sales ss
    JOIN sales_hierarchy sh ON ss.ss_store_sk = sh.ss_store_sk
    WHERE sh.level < 5
    GROUP BY ss.ss_store_sk, sh.total_sales, sh.total_revenue, sh.level
), 
orders_summary AS (
    SELECT 
        ws.bill_customer_sk,
        COUNT(ws.order_number) AS total_web_orders,
        SUM(ws.net_paid_inc_tax) AS total_web_sales
    FROM web_sales ws
    WHERE ws.sold_date_sk >= (
        SELECT MAX(d_date_sk) - 30 FROM date_dim
    )
    GROUP BY ws.bill_customer_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(os.total_web_orders, 0) AS total_web_orders,
        COALESCE(os.total_web_sales, 0) AS total_web_sales,
        SUM(CASE WHEN inv.inv_quantity_on_hand < 10 THEN 1 ELSE 0 END) AS low_stock_items
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN orders_summary os ON c.c_customer_sk = os.bill_customer_sk
    LEFT JOIN inventory inv ON c.c_current_addr_sk = inv.inv_item_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, 
        cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT 
    ca.c_first_name,
    ca.c_last_name,
    ca.cd_gender,
    ca.total_web_orders,
    ca.total_web_sales,
    sh.store_sk,
    sh.total_sales,
    sh.total_revenue
FROM customer_analysis ca
JOIN sales_hierarchy sh ON ca.c_customer_sk = sh.ss_store_sk
ORDER BY ca.total_web_sales DESC, sh.total_revenue ASC
LIMIT 100;
