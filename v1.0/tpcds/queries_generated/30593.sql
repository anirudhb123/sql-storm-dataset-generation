
WITH RecursiveSales AS (
    SELECT ss_sold_date_sk, ss_item_sk, ss_quantity, ss_net_paid, 
           ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk DESC) AS rn
    FROM store_sales
    WHERE ss_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price > 50)
),
CustomerStats AS (
    SELECT c.c_customer_sk, COUNT(DISTINCT wr_order_number) AS web_returns_count,
           SUM(COALESCE(wr_return_amt, 0)) AS total_return_amount
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr_returning_customer_sk
    GROUP BY c.c_customer_sk
),
HighValueCustomers AS (
    SELECT c.c_customer_sk, cd.cd_gender, cd.cd_marital_status,
           SUM(ws_net_paid) AS total_spending
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ws_net_paid) > 1000
),
DailySales AS (
    SELECT d.d_date, SUM(ws_net_paid) AS daily_sales, 
           RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
),
TopSalesDays AS (
    SELECT d_date 
    FROM DailySales 
    WHERE sales_rank <= 10
)
SELECT c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, 
       COALESCE(cs.web_returns_count, 0) AS web_returns_count, 
       COALESCE(cs.total_return_amount, 0) AS total_return_amount, 
       hvc.total_spending, 
       CASE WHEN hvc.total_spending IS NOT NULL THEN 'High Value' ELSE 'Regular' END AS customer_type,
       ds.daily_sales
FROM customer c
LEFT JOIN CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN HighValueCustomers hvc ON c.c_customer_sk = hvc.c_customer_sk
JOIN DailySales ds ON ds.sales_rank <= 10
LEFT JOIN TopSalesDays ts ON ds.d_date = ts.d_date
WHERE ds.daily_sales > (
    SELECT AVG(daily_sales) FROM DailySales
) OR ts.d_date IS NOT NULL
ORDER BY c.c_customer_id;
