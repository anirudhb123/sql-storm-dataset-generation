
WITH RECURSIVE Sales_CTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, SUM(ws_quantity) AS total_sales, 
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
), Ranked_Sales AS (
    SELECT ws_item_sk, SUM(total_sales) AS overall_sales
    FROM Sales_CTE
    WHERE sales_rank <= 5
    GROUP BY ws_item_sk
), Customer_Info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
           cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating,
           COUNT(DISTINCT ws_order_number) AS order_count,
           SUM(ws_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
             cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
)
SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender,
       ci.cd_marital_status, ci.total_spent, 
       CASE 
           WHEN ci.order_count > 10 THEN 'Frequent'
           WHEN ci.order_count BETWEEN 5 AND 10 THEN 'Occasional'
           ELSE 'Rare'
       END AS customer_type,
       rs.overall_sales, (rs.overall_sales / NULLIF(SUM(rs.overall_sales) OVER (), 0)) * 100 AS sales_percentage
FROM Customer_Info ci
JOIN Ranked_Sales rs ON ci.c_customer_sk = (SELECT sr_ship_customer_sk FROM store_returns sr WHERE sr_item_sk = rs.ws_item_sk LIMIT 1)
WHERE ci.total_spent IS NOT NULL
ORDER BY ci.total_spent DESC
LIMIT 100;
