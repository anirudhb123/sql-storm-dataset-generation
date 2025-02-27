
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT ch.c_customer_sk,
           ch.c_first_name,
           ch.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_hdemo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status IS NOT NULL
),
DateStats AS (
    SELECT d.d_year, 
           COUNT(DISTINCT cs.cs_order_number) AS total_orders, 
           SUM(cs.cs_net_paid) AS total_sales
    FROM date_dim d
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY d.d_year
),
TopItems AS (
    SELECT i.i_item_id,
           i.i_item_desc,
           SUM(ws.ws_quantity) AS total_sold,
           SUM(ws.ws_sales_price) AS total_revenue
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id, i.i_item_desc
    ORDER BY total_revenue DESC
    LIMIT 10
)
SELECT ch.c_first_name, 
       ch.c_last_name, 
       ch.cd_gender,
       ds.d_year,
       ds.total_orders,
       ds.total_sales,
       ti.i_item_desc,
       ti.total_sold,
       (CASE WHEN ti.total_sold > 100 THEN 'High Demand' ELSE 'Low Demand' END) AS demand_status,
       COALESCE(ch.cd_purchase_estimate, 0) AS purchase_estimate
FROM CustomerHierarchy ch
CROSS JOIN DateStats ds
JOIN TopItems ti ON ds.total_orders > 50
WHERE ch.cd_purchase_estimate > (
        SELECT AVG(cd.cd_purchase_estimate) FROM customer_demographics cd
    )
AND (ch.cd_gender = 'F' OR ch.cd_marital_status = 'S')
ORDER BY ds.d_year DESC, ti.total_revenue DESC;
