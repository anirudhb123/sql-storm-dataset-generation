
WITH RECURSIVE NameParts AS (
    SELECT c_customer_sk, 
           CAST(c_first_name AS VARCHAR(20)) AS part_name, 
           1 AS part_level 
    FROM customer 
    UNION ALL 
    SELECT c_customer_sk, 
           SUBSTRING_INDEX(part_name, ' ', 1) AS part_name, 
           part_level + 1 
    FROM NameParts 
    WHERE LENGTH(part_name) > 0
),
GroupedNames AS (
    SELECT c_customer_sk, 
           GROUP_CONCAT(part_name ORDER BY part_level SEPARATOR ' ') AS full_name 
    FROM NameParts 
    GROUP BY c_customer_sk
),
CustomerDetails AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           g.full_name, 
           d.d_date AS purchase_date, 
           SUM(ws.ws_sales_price) AS total_sales 
    FROM customer AS c 
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    JOIN date_dim AS d ON d.d_date_sk = ws.ws_sold_date_sk 
    JOIN GroupedNames AS g ON c.c_customer_sk = g.c_customer_sk 
    WHERE d.d_year = 2023 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, g.full_name, d.d_date 
)
SELECT cd.c_customer_sk, 
       cd.full_name, 
       cd.purchase_date, 
       cd.total_sales, 
       RANK() OVER (PARTITION BY cd.purchase_date ORDER BY cd.total_sales DESC) AS sales_rank 
FROM CustomerDetails cd 
WHERE cd.total_sales > 1000 
ORDER BY cd.purchase_date, sales_rank;
