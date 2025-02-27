
WITH RECURSIVE sales_history AS (
    SELECT ss_sold_date_sk, ss_item_sk, ss_quantity, ss_net_paid
    FROM store_sales
    WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    
    UNION ALL

    SELECT ss.sold_date_sk, ss.item_sk, ss.quantity, ss.net_paid
    FROM store_sales ss
    JOIN sales_history sh ON ss.ss_item_sk = sh.ss_item_sk
    WHERE ss.ss_sold_date_sk < sh.ss_sold_date_sk
),
top_sales AS (
    SELECT 
        sh.ss_item_sk,
        SUM(sh.ss_quantity) AS total_quantity,
        SUM(sh.ss_net_paid) AS total_net_sales,
        DENSE_RANK() OVER (ORDER BY SUM(sh.ss_net_paid) DESC) AS rank
    FROM sales_history sh
    GROUP BY sh.ss_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
),
address_summary AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        STRING_AGG(DISTINCT c.c_city, ', ') AS cities
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk
)
SELECT 
    cs.c_customer_sk,
    cs.order_count,
    cs.total_spent,
    cs.avg_sales_price,
    asa.customer_count,
    asa.cities,
    ts.total_quantity,
    ts.total_net_sales
FROM customer_summary cs
JOIN address_summary asa ON cs.c_customer_sk = asa.ca_address_sk
JOIN top_sales ts ON cs.c_customer_sk = ts.ss_item_sk 
WHERE 
    cs.total_spent > 1000 AND
    asa.customer_count IS NOT NULL
ORDER BY cs.total_spent DESC
LIMIT 100;
