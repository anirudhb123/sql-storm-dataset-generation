
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           cd.cd_demo_sk, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
    UNION ALL
    SELECT sh.c_customer_sk, 
           sh.c_customer_id, 
           sh.cd_demo_sk, 
           sh.cd_gender, 
           sh.cd_marital_status, 
           sh.total_sales + COALESCE(ws_ext_sales_sales, 0)
    FROM sales_hierarchy sh
    LEFT JOIN web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        COALESCE(sh.total_sales, 0) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY COALESCE(sh.total_sales, 0) DESC) AS sales_rank
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN sales_hierarchy sh ON c.c_customer_sk = sh.c_customer_sk
)
SELECT 
    cd.c_customer_id,
    cd.ca_city,
    cd.ca_state,
    cd.total_sales,
    CASE 
        WHEN cd.sales_rank <= 10 THEN 'Top 10 Sales'
        WHEN cd.sales_rank BETWEEN 11 AND 20 THEN 'Top 20 Sales'
        ELSE 'Other'
    END AS sales_category
FROM customer_details cd
WHERE cd.total_sales > 1000
ORDER BY cd.ca_state, cd.total_sales DESC;
