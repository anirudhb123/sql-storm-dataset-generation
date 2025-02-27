
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_quantity,
        cs.total_profit
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.rank <= 10
),
StoreSalesDetails AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    s.s_store_sk,
    s.s_store_name,
    COALESCE(ssd.total_quantity, 0) AS total_store_quantity,
    COALESCE(ssd.total_profit, 0) AS total_store_profit,
    HVC.c_first_name,
    HVC.c_last_name,
    HVC.total_quantity AS customer_quantity,
    HVC.total_profit AS customer_profit
FROM 
    store s
LEFT JOIN 
    StoreSalesDetails ssd ON s.s_store_sk = ssd.ss_store_sk
LEFT JOIN 
    HighValueCustomers HVC ON HVC.c_customer_sk = (SELECT TOP 1 c_customer_sk FROM web_sales WHERE ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022))
ORDER BY 
    total_store_profit DESC, 
    customer_profit DESC;
