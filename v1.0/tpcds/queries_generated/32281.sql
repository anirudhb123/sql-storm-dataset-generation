
WITH RECURSIVE ItemRevenue AS (
    SELECT i.i_item_sk, 
           i.i_item_id, 
           i.i_item_desc, 
           SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451515 AND 2451540 -- Example date range
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc

    UNION ALL

    SELECT i.i_item_sk, 
           i.i_item_id, 
           i.i_item_desc, 
           SUM(cs.cs_ext_sales_price) AS total_revenue
    FROM item i
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451515 AND 2451540 -- Example date range
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc
),
TopItems AS (
    SELECT ir.i_item_id, 
           ir.i_item_desc, 
           ir.total_revenue,
           RANK() OVER (ORDER BY ir.total_revenue DESC) AS revenue_rank
    FROM ItemRevenue ir
)
SELECT 
    ci.c_customer_id, 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.c_birth_country, 
    COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
    COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
    COALESCE(TI.total_revenue, 0) AS item_revenue
FROM customer ci
LEFT JOIN store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
LEFT JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN TopItems TI ON ci.c_customer_sk = TI.i_item_id -- Assuming item_id relates to customer id
WHERE ci.c_birth_country = 'USA'
  AND (TI.total_revenue > 1000 OR TI.total_revenue IS NULL)
GROUP BY ci.c_customer_id, ci.c_first_name, ci.c_last_name, ci.c_birth_country
HAVING total_store_sales > 1000 
   OR total_web_sales > 1000
ORDER BY item_revenue DESC
LIMIT 10;
