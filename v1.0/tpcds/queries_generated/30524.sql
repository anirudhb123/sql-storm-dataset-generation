
WITH RECURSIVE CustomerCTE AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ca.city AS address_city,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ca.ca_city) AS rn
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_month = 12
)
, SalesCTE AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.address_city,
    COALESCE(s.total_sales, 0) AS total_sales,
    s.order_count,
    CASE 
        WHEN s.sales_rank IS NULL THEN 'No Sales'
        WHEN s.sales_rank <= 10 THEN 'Top Sales'
        ELSE 'Regular Customer'
    END AS customer_type
FROM CustomerCTE c
LEFT JOIN SalesCTE s ON c.c_customer_sk = s.customer_sk
LEFT JOIN customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
LEFT JOIN date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
WHERE cd.cd_marital_status = 'M' 
AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
ORDER BY total_sales DESC, c.c_last_name, c.c_first_name
LIMIT 100;
