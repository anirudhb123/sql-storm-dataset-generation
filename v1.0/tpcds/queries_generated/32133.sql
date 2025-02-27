
WITH RECURSIVE Sales_CTE AS (
    SELECT w.ws_item_sk, 
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_ext_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY w.ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales w
    JOIN date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY w.ws_item_sk
    
    UNION ALL
    
    SELECT w.ws_item_sk, 
           SUM(ws_quantity) + s.total_quantity,
           SUM(ws_ext_sales_price) + s.total_sales,
           ROW_NUMBER() OVER (PARTITION BY w.ws_item_sk ORDER BY (SUM(ws_ext_sales_price) + s.total_sales) DESC) AS rank
    FROM web_sales w
    JOIN date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    JOIN Sales_CTE s ON w.ws_item_sk = s.ws_item_sk
    WHERE d.d_year = 2022
    GROUP BY w.ws_item_sk, s.total_quantity, s.total_sales
),
Customer_Returns AS (
    SELECT sr_returned_date_sk,
           COUNT(sr_ticket_number) AS total_returns,
           SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
    GROUP BY sr_returned_date_sk
),
Customer_Demographics AS (
    SELECT cd.cd_gender, 
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
Promotion_Summary AS (
    SELECT p.p_promo_sk,
           COUNT(DISTINCT p.p_promo_id) AS promo_count,
           AVG(p.p_cost) AS avg_cost
    FROM promotion p
    GROUP BY p.p_promo_sk
)
SELECT sd.rank, 
       s.total_quantity, 
       s.total_sales, 
       coalesce(cr.total_returns, 0) AS total_returns,
       coalesce(cr.total_return_amount, 0) AS total_return_amount,
       cd.customer_count,
       ps.promo_count,
       ps.avg_cost
FROM Sales_CTE s
LEFT JOIN Customer_Returns cr ON s.ws_item_sk = cr.sr_returned_date_sk
JOIN Customer_Demographics cd ON cd.customer_count > 0
JOIN Promotion_Summary ps ON ps.promo_count > 0
ORDER BY s.total_sales DESC
LIMIT 100;
