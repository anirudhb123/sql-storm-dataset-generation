
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
TopWebsites AS (
    SELECT 
        web_site_sk,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    wc.w_warehouse_id,
    wc.w_warehouse_name,
    SUM(ws.ws_net_paid) AS total_revenue,
    COALESCE(hvc.total_spent, 0) AS high_value_customer_spending,
    COUNT(DISTINCT hvc.c_customer_sk) AS unique_customers
FROM 
    store s
JOIN 
    web_site wc ON s.s_store_id = wc.web_site_id
LEFT JOIN 
    web_sales ws ON wc.web_site_sk = ws.ws_web_site_sk
LEFT JOIN 
    HighValueCustomers hvc ON ws.ws_bill_customer_sk = hvc.c_customer_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
GROUP BY 
    wc.w_warehouse_id, wc.w_warehouse_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
