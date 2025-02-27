
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;

WITH AvgSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        (
            SELECT 
                c.c_customer_sk,
                SUM(ws.ws_ext_sales_price) AS total_sales
            FROM 
                customer c
            JOIN 
                web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
            WHERE 
                ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                       AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
            GROUP BY 
                c.c_customer_sk
        ) AS inner_sales
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_ext_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                           AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name
HAVING 
    total_sales > (SELECT avg_sales FROM AvgSales)
ORDER BY 
    total_sales DESC;
