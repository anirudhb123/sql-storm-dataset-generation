
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        1 AS level
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE 
        ch.level < 3
),
SalesData AS (
    SELECT 
        w.ws_sold_date_sk,
        SUM(w.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT w.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY w.ws_sold_date_sk ORDER BY SUM(w.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales w
    GROUP BY 
        w.ws_sold_date_sk
),
CustomerSales AS (
    SELECT 
        ch.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_customer_profit
    FROM 
        CustomerHierarchy ch
    JOIN 
        web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ch.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_customer_profit,
        RANK() OVER (ORDER BY cs.total_customer_profit DESC) AS customer_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_customer_profit > 0
),
CombinedData AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.total_net_profit,
        COALESCE(tc.total_customer_profit, 0) AS total_customer_profit,
        tc.customer_rank
    FROM 
        SalesData sd
    LEFT JOIN 
        TopCustomers tc ON sd.ws_sold_date_sk = tc.c_customer_sk
)
SELECT 
    dd.d_date_id,
    cd.total_customer_profit,
    cd.total_net_profit,
    CASE 
        WHEN cd.total_customer_profit = 0 THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM 
    date_dim dd
LEFT JOIN 
    CombinedData cd ON dd.d_date_sk = cd.ws_sold_date_sk
WHERE 
    dd.d_year = 2023
ORDER BY 
    dd.d_date_sk, cd.customer_rank
