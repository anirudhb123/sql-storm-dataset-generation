
WITH RankedWebSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2023
        AND dd.d_weekend = '1'
    GROUP BY 
        ws.web_site_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_paid) > (SELECT AVG(ws_total) FROM (SELECT SUM(ws.net_paid) AS ws_total FROM web_sales ws GROUP BY ws.ws_ship_customer_sk) AS avg_ws)
),
SalesReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0 
    GROUP BY 
        sr_item_sk
),
FinalReport AS (
    SELECT 
        RWS.web_site_sk,
        HVC.c_first_name || ' ' || HVC.c_last_name AS customer_name,
        RWS.total_sales,
        HVC.total_spent,
        COALESCE(SR.total_returns, 0) AS total_returns,
        COALESCE(SR.total_return_amount, 0.00) AS total_return_amount
    FROM 
        RankedWebSales RWS
    JOIN 
        HighValueCustomers HVC ON RWS.web_site_sk = (SELECT MIN(ws.web_site_sk) FROM web_sales ws WHERE ws.ws_net_paid IS NOT NULL AND ws.ws_sold_date_sk BETWEEN 20200101 AND 20230101)
    LEFT JOIN 
        SalesReturns SR ON RWS.web_site_sk = SR.sr_item_sk
    WHERE 
        RWS.rank <= 5
)
SELECT 
    *,
    CASE 
        WHEN total_returns > 0 THEN total_sales - total_return_amount
        ELSE total_sales
    END AS net_sales
FROM 
    FinalReport
ORDER BY 
    total_sales DESC;
