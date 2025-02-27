
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
ProfitableSites AS (
    SELECT 
        web_site_sk, 
        web_name, 
        total_net_profit, 
        total_orders
    FROM 
        SalesCTE
    WHERE 
        rank <= 10
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent,
        MAX(EXTRACT(YEAR FROM dd.d_date)) AS last_purchase_year
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ps.web_name,
    ps.total_net_profit,
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_spent,
    (CASE WHEN cs.last_purchase_year < 2023 THEN 'Inactive' ELSE 'Active' END) AS customer_status
FROM 
    ProfitableSites ps
JOIN 
    CustomerStats cs ON ps.web_site_sk IN (
        SELECT 
            ws.web_site_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_net_profit > 10000
    )
ORDER BY 
    ps.total_net_profit DESC, cs.total_orders DESC;
