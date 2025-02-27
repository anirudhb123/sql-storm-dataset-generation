
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_current_cdemo_sk, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
           ch.c_current_cdemo_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate, 
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
ranked_customers AS (
    SELECT c.*, 
           ROW_NUMBER() OVER (PARTITION BY c.cd_gender ORDER BY c.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_sales AS (
    SELECT 
        i.i_item_sk, 
        SUM(ws.ws_quantity) AS total_sold, 
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE ws.ws_ship_date_sk IS NOT NULL
    GROUP BY i.i_item_sk
),
sales_summary AS (
    SELECT 
        sum(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_sale_date
    FROM web_sales ws
    WHERE ws.ws_item_sk IN (SELECT i.i_item_sk FROM item_sales i)
),
final_report AS (
    SELECT 
        cu.c_first_name || ' ' || cu.c_last_name AS full_name,
        cu.cd_gender,
        cu.cd_marital_status,
        cu.cd_purchase_estimate,
        is.total_sold,
        is.avg_sales_price,
        is.total_discount,
        ss.total_sales,
        ss.total_orders,
        CASE 
            WHEN ss.last_sale_date IS NULL THEN 'No Sales'
            ELSE 'Sales Present'
        END AS sale_status
    FROM ranked_customers cu
    JOIN item_sales is ON cu.c_current_cdemo_sk = is.i_item_sk
    CROSS JOIN sales_summary ss
    WHERE cu.rank = 1
      AND (cu.cd_gender = 'M' OR cu.cd_gender = 'F') 
      AND (cu.cd_purchase_estimate BETWEEN 100 AND 1000 OR cu.cd_purchase_estimate IS NULL)
    ORDER BY cu.cd_purchase_estimate DESC
)
SELECT * FROM final_report
WHERE sale_status = 'Sales Present'
  AND (cd_gender IS NOT NULL OR cd_gender IS NULL)
  AND (full_name LIKE '%John%' OR full_name LIKE '%Jane%')
  AND (sale_status IS NOT NULL OR total_sales IS NULL)
LIMIT 100 OFFSET 10;
