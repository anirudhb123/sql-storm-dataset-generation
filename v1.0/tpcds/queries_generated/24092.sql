
WITH RankedSales AS (
    SELECT ws.customer_sk, ws.web_site_sk, ws.order_number,
           SUM(ws.net_profit) AS total_net_profit,
           ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM web_sales ws
    GROUP BY ws.customer_sk, ws.web_site_sk, ws.order_number
),
CustomerStats AS (
    SELECT c.customer_sk, c.first_name, c.last_name, 
           cd.gender, cd.marital_status, cd.education_status,
           COUNT(DISTINCT ws.order_number) AS order_count,
           COALESCE(MAX(ws.net_paid), 0) AS max_spent,
           COALESCE(MIN(ws.net_paid), 0) AS min_spent,
           COALESCE(AVG(ws.net_paid), 0) AS avg_spent,
           cd.dep_count, cd.dep_college_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    LEFT JOIN web_sales ws ON c.customer_sk = ws.bill_customer_sk
    GROUP BY c.customer_sk, c.first_name, c.last_name, cd.gender, cd.marital_status, cd.education_status, cd.dep_count, cd.dep_college_count
),
TopCustomers AS (
    SELECT cs.*, rs.total_net_profit
    FROM CustomerStats cs
    LEFT JOIN RankedSales rs ON cs.customer_sk = rs.customer_sk
    WHERE rs.rank <= 10
)
SELECT t.first_name, t.last_name, t.order_count, 
       CASE 
           WHEN t.avg_spent IS NULL THEN 'No Spending' 
           ELSE CONCAT('Average Spending: ', ROUND(t.avg_spent, 2)) 
       END AS spending_info,
       CASE 
           WHEN t.dep_college_count > 0 THEN 'Has College Dependent'
           ELSE 'No College Dependent' 
       END AS dependency_info,
       COALESCE(t.total_net_profit, 0) AS total_net_profit
FROM TopCustomers t
WHERE (t.gender = 'F' OR t.marital_status = 'S')
  AND (t.max_spent > 100)
ORDER BY t.total_net_profit DESC
LIMIT 25;
