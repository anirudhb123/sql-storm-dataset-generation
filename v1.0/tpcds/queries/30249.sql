
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, 1 AS level
    FROM item
    WHERE i_item_sk < 1000  
    
    UNION ALL
    
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON i.i_item_sk = ih.i_item_sk + 1  
    WHERE ih.level < 5  
),
monthly_sales AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT 
    ih.i_item_desc,
    ih.i_current_price,
    ms.d_month_seq,
    ms.total_sales,
    ci.order_count,
    ci.cd_gender,
    ci.cd_marital_status
FROM item_hierarchy ih
LEFT JOIN monthly_sales ms ON ms.d_month_seq = EXTRACT(MONTH FROM DATE '2002-10-01')
LEFT JOIN customer_info ci ON ci.order_count > 5
WHERE ih.i_current_price BETWEEN 10 AND 100
  AND ci.cd_marital_status IS NOT NULL
ORDER BY ms.total_sales DESC, ih.i_item_desc
LIMIT 100;
