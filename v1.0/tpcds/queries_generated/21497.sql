
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.s_store_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN store s ON ws.ws_ship_addr_sk = s.s_addr_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_moy IN (1, 2, 3) 
                AND (d_dow BETWEEN 1 AND 5)  -- Weekdays only
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, s.s_store_name
    HAVING 
        SUM(ws.ws_ext_sales_price) > 1000
),
TopCustomers AS (
    SELECT 
        customer_sk,
        c_first_name,
        c_last_name,
        total_sales,
        RANK() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS rank
    FROM 
        SalesHierarchy
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    s.s_store_name,
    COALESCE(t.total_sales, 0) AS total_sales,
    CASE 
        WHEN t.rank <= 3 THEN 'Top 3 Customer'
        ELSE 'Other'
    END AS customer_rank
FROM 
    customer c
LEFT JOIN TopCustomers t ON c.c_customer_sk = t.customer_sk
JOIN store s ON t.s_store_name = s.s_store_name
WHERE 
    t.total_sales IS NOT NULL 
    OR NOT EXISTS (
        SELECT 1 FROM store_sales ss 
        WHERE ss.ss_customer_sk = c.c_customer_sk 
        AND ss.ss_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023
        ) AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
        )
    )
ORDER BY 
    s.s_store_name, full_name;
