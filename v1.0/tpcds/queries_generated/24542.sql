
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_item_sk) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 10000 AND 20000
    UNION ALL
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid_inc_tax
    FROM catalog_sales cs
    INNER JOIN sales_data sd ON cs.cs_order_number = sd.ws_order_number
    WHERE sd.rn <= 5
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_profit,
        SUM(COALESCE(cs.cs_net_profit, 0)) AS total_catalog_profit,
        MAX(cd.cd_purchase_estimate) AS max_estimate,
        MIN(cd.cd_credit_rating) AS min_rating
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_data sd ON sd.ws_item_sk IN (
        SELECT i.i_item_sk
        FROM item i
        WHERE i.i_current_price IS NOT NULL
    )
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
ranked_customers AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY total_web_profit DESC) AS customer_rank
    FROM customer_info c
)
SELECT 
    rc.c_customer_id,
    rc.catalog_order_count,
    rc.web_order_count,
    rc.total_web_profit,
    rc.total_catalog_profit,
    CASE 
        WHEN rc.catalog_order_count IS NULL THEN 'No Catalog Orders'
        WHEN rc.web_order_count IS NULL THEN 'No Web Orders'
        ELSE 'Both Types of Orders'
    END AS order_type,
    (SELECT AVG(total_web_profit) FROM ranked_customers) AS avg_web_profit,
    (SELECT AVG(total_catalog_profit) FROM ranked_customers) AS avg_catalog_profit
FROM ranked_customers rc
WHERE rc.customer_rank <= 10
ORDER BY rc.total_web_profit DESC, rc.total_catalog_profit ASC;
