
WITH RECURSIVE hierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate,
           NULL AS parent_customer_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_customer_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate, 
           h.c_customer_sk
    FROM customer c
    JOIN hierarchy h ON c.c_current_cdemo_sk = h.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
customer_sales AS (
    SELECT ws.bill_customer_sk, 
           SUM(ws.net_paid) AS total_sales, 
           COUNT(DISTINCT ws.order_number) AS order_count
    FROM web_sales ws
    WHERE ws.sold_date_sk > 0
    GROUP BY ws.bill_customer_sk
),
customer_info AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COALESCE(cs.total_sales, 0) AS total_sales,
           COALESCE(cs.order_count, 0) AS order_count
    FROM customer c
    LEFT JOIN customer_sales cs ON c.c_customer_sk = cs.bill_customer_sk
),
high_value_customers AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY c_gender ORDER BY total_sales DESC) AS sales_rank
    FROM (
        SELECT ci.*,  cd.cd_gender
        FROM customer_info ci
        JOIN customer_demographics cd ON ci.c_customer_sk = cd.cd_demo_sk
        WHERE ci.total_sales > (
            SELECT AVG(total_sales) 
            FROM customer_info 
            WHERE total_sales IS NOT NULL
        )
    ) ranked_customers
)
SELECT h.c_first_name || ' ' || h.c_last_name AS customer_name,
       h.c_gender,
       h.sales_rank,
       h.total_sales,
       (SELECT COUNT(*)
        FROM customer_info ci
        WHERE ci.total_sales > h.total_sales) AS higher_sales_count,
       (SELECT COUNT(DISTINCT ws.order_number)
        FROM web_sales ws
        WHERE ws.bill_customer_sk IN (SELECT c_customer_sk FROM high_value_customers WHERE ci.total_sales IS NOT NULL)
          AND ws.sold_date_sk BETWEEN (SELECT MIN(d_date_sk) 
                                       FROM date_dim 
                                       WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) 
                                                                  FROM date_dim 
                                                                  WHERE d_year = 2023)) AS orders_current_year
FROM high_value_customers h
WHERE h.sales_rank <= 10
ORDER BY h.total_sales DESC;
