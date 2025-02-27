
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        1 AS level
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
    
    UNION ALL
    
    SELECT 
        sh.c_customer_sk,
        sh.c_customer_id,
        COALESCE(SUM(ws.ws_net_profit), 0) + sh.total_profit AS total_profit,
        sh.level + 1
    FROM 
        SalesHierarchy sh
    LEFT JOIN 
        web_sales ws ON sh.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        sh.level < 5
    GROUP BY 
        sh.c_customer_sk, sh.c_customer_id, sh.total_profit
),
FilteredSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022 AND 
        (ws.ws_net_profit > 100 OR ws.ws_quantity > 5)
),
TotalSales AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_tax) AS total_sales_tax,
        COUNT(*) AS total_transactions
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    t.total_profit,
    COALESCE(fs.total_sales, 0) AS sales_last_year,
    (COALESCE(fs.total_sales_tax, 0) / NULLIF(fs.total_sales, 0)) AS tax_rate,
    th.level AS sales_depth
FROM 
    SalesHierarchy t
LEFT JOIN 
    FilteredSales fs ON t.c_customer_sk = fs.ws_item_sk 
LEFT JOIN 
    customer c ON t.c_customer_sk = c.c_customer_sk
JOIN 
    TotalSales ts ON 1 = 1 
LEFT JOIN 
    (SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk) net ON net.ws_bill_customer_sk = c.c_customer_sk
ORDER BY 
    t.total_profit DESC, c.c_last_name 
LIMIT 100;
