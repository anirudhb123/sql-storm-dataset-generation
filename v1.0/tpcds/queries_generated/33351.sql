
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        1 AS level,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.level + 1,
        SUM(ws.ws_net_profit)
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        SalesHierarchy sh ON sh.c_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, sh.level
),

TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(ws.ws_net_profit, 0)) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(COALESCE(ws.ws_net_profit, 0)) > 1000
),

FilteredSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_sales_price) AS total_sales,
        COUNT(*) AS orders_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_sales_price) DESC) AS row_num
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
)

SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(ts.total_net_profit, 0) AS total_net_profit,
    COALESCE(fs.total_sales, 0) AS total_sales,
    fs.orders_count,
    sh.level
FROM 
    customer c
LEFT JOIN 
    TopCustomers ts ON c.c_customer_sk = ts.c_customer_sk
LEFT JOIN 
    FilteredSales fs ON c.c_customer_sk = fs.c_customer_sk
LEFT JOIN 
    SalesHierarchy sh ON c.c_customer_sk = sh.c_customer_sk
WHERE 
    c.c_birth_year IS NOT NULL 
    AND (c.c_gender = 'F' OR c.c_gender IS NULL)
ORDER BY 
    total_net_profit DESC,
    total_sales DESC
LIMIT 50;
