
WITH RECURSIVE Customer_Hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_current_cdemo_sk, 0 AS level 
    FROM customer c 
    WHERE c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_current_cdemo_sk, ch.level + 1 
    FROM customer c
    JOIN Customer_Hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk 
    WHERE ch.level < 2
), 
Sales_Summary AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity,
           AVG(ws.ws_sales_price) AS avg_sales_price,
           SUM(ws.ws_ext_discount_amt) AS total_discount 
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk IS NOT NULL 
    GROUP BY ws.ws_item_sk
),
Top_Items AS (
    SELECT i.i_item_sk, i.i_item_id, i.i_product_name,
           COALESCE(ss.total_quantity, 0) AS total_quantity,
           COALESCE(ss.avg_sales_price, 0) AS avg_sales_price
    FROM item i
    LEFT JOIN Sales_Summary ss ON i.i_item_sk = ss.ws_item_sk
    WHERE i.i_current_price > 0 
    AND (ss.total_quantity IS NULL OR ss.total_quantity > 10)
)
SELECT ch.c_first_name, ch.c_last_name, ti.i_item_id, 
       ti.i_product_name, ti.total_quantity, ti.avg_sales_price,
       RANK() OVER (PARTITION BY ch.level ORDER BY ti.total_quantity DESC) AS item_rank
FROM Customer_Hierarchy ch
JOIN Top_Items ti ON ch.c_current_cdemo_sk = ch.c_current_cdemo_sk
LEFT JOIN customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F' 
   AND cd.cd_marital_status = 'M' 
   AND (cd.cd_credit_rating IS NULL OR cd.cd_credit_rating <> 'Bad')
ORDER BY item_rank, ch.c_last_name, ch.c_first_name;
