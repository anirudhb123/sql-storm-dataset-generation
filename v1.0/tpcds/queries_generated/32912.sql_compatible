
WITH RECURSIVE SalesHierarchy AS (
    SELECT s.s_store_sk, s.s_store_name, s.s_city, s.s_state, s.s_country, 
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM store s
    JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY s.s_store_sk, s.s_store_name, s.s_city, s.s_state, s.s_country

    UNION ALL

    SELECT r.s_store_sk, r.s_store_name, r.s_city, r.s_state, r.s_country, 
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM SalesHierarchy r
    JOIN store s ON r.s_store_sk = s.s_store_sk
    JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    WHERE ws.ws_sold_date_sk = r.s_store_sk + 1
    GROUP BY r.s_store_sk, r.s_store_name, r.s_city, r.s_state, r.s_country
),
CustomerRanking AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS customer_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name
    FROM CustomerRanking c
    WHERE c.customer_rank <= 10
)
SELECT sh.s_store_name, sh.s_city, sh.s_state, sh.total_sales,
       COALESCE(CONCAT(tc.c_first_name, ' ', tc.c_last_name), 'No Top Customer') AS top_customer
FROM SalesHierarchy sh
LEFT JOIN TopCustomers tc ON sh.s_store_sk = tc.c_customer_sk
WHERE sh.total_sales > (SELECT AVG(total_sales) FROM SalesHierarchy)
ORDER BY sh.total_sales DESC;
