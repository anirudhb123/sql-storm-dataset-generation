
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn,
        SUM(ws.ws_ext_sales_price) OVER (PARTITION BY ws.web_site_sk) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1980 AND c.c_birth_year <= 2000
),
TopSales AS (
    SELECT 
        web_site_sk,
        ws_order_number,
        ws_item_sk,
        ws_net_profit,
        total_sales
    FROM 
        RankedSales
    WHERE 
        rn <= 5
),
SalesReturns AS (
    SELECT 
        sr.returning_customer_sk,
        SUM(sr.returned_quantity) AS total_returned
    FROM 
        store_returns sr
    GROUP BY 
        sr.returning_customer_sk
)
SELECT 
    ts.web_site_sk,
    COUNT(DISTINCT ts.ws_order_number) AS number_of_orders,
    ROUND(AVG(ts.ws_net_profit), 2) AS avg_net_profit,
    COALESCE(SUM(sr.total_returned), 0) AS total_returns,
    CASE 
        WHEN SUM(ts.total_sales) = 0 THEN 'No Sales' 
        ELSE 'Sales Present' 
    END AS sales_status
FROM 
    TopSales ts
LEFT JOIN 
    SalesReturns sr ON ts.web_site_sk = sr.returning_customer_sk
GROUP BY 
    ts.web_site_sk;
