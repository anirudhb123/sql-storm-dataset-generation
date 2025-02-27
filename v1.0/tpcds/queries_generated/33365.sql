
WITH RECURSIVE SalesCTE AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_net_paid) AS total_sales,
           ROW_NUMBER() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_paid) > 1000
),
CustomerCTE AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           d.d_year,
           cd.cd_gender,
           COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE cd.cd_gender IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, cd.cd_gender
),
RankedCustomers AS (
    SELECT c.*, 
           RANK() OVER (PARTITION BY c.d_year ORDER BY c.total_spent DESC) AS customer_rank
    FROM CustomerCTE c
)
SELECT r.c_first_name,
       r.c_last_name,
       r.total_spent,
       r.d_year,
       r.cd_gender,
       s.total_quantity,
       s.total_sales
FROM RankedCustomers r
LEFT JOIN SalesCTE s ON r.c_customer_sk = s.ws_item_sk
WHERE r.customer_rank <= 10
ORDER BY r.d_year, r.total_spent DESC
UNION ALL
SELECT 'Total' AS c_first_name,
       NULL AS c_last_name,
       SUM(total_spent) AS total_spent,
       d_year,
       NULL AS cd_gender,
       SUM(total_quantity) AS total_quantity,
       SUM(total_sales) AS total_sales
FROM (
    SELECT r.d_year,
           r.total_spent,
           s.total_quantity,
           s.total_sales
    FROM RankedCustomers r
    LEFT JOIN SalesCTE s ON r.c_customer_sk = s.ws_item_sk
) AS TotalSales
GROUP BY d_year
ORDER BY d_year DESC;
