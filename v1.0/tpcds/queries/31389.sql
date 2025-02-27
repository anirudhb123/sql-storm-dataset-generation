
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        CASE 
            WHEN COALESCE(SUM(ws.ws_net_profit), 0) > 1000 THEN 'High'
            WHEN COALESCE(SUM(ws.ws_net_profit), 0) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
FilteredSales AS (
    SELECT * FROM SalesHierarchy
    WHERE rn = 1
),
TopCustomers AS (
    SELECT 
        fs.c_customer_sk,
        fs.c_first_name,
        fs.c_last_name,
        fs.total_profit,
        fs.profit_category,
        ROW_NUMBER() OVER (ORDER BY fs.total_profit DESC) AS rank
    FROM 
        FilteredSales fs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name || ' ' || tc.c_last_name AS full_name,
    tc.total_profit,
    tc.profit_category,
    d.d_year,
    d.d_month_seq,
    (SELECT COUNT(DISTINCT(ws.ws_order_number)) 
     FROM web_sales ws 
     WHERE ws.ws_ship_customer_sk = tc.c_customer_sk) AS order_count,
    (SELECT AVG(ws.ws_net_profit) 
     FROM web_sales ws 
     WHERE ws.ws_ship_customer_sk = tc.c_customer_sk) AS avg_order_profit
FROM 
    TopCustomers tc
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_ship_date_sk) FROM web_sales ws WHERE ws.ws_ship_customer_sk = tc.c_customer_sk)
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_profit DESC;
