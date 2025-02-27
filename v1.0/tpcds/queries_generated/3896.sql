
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20211231
    GROUP BY 
        ws.web_site_sk
),
TopWebSites AS (
    SELECT 
        r.web_site_sk, 
        r.total_sales
    FROM 
        RankedSales AS r
    WHERE 
        r.rank_sales <= 5
),
CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
        SUM(CASE WHEN sr.sr_return_quantity IS NOT NULL THEN sr.sr_return_amt_inc_tax ELSE 0 END) AS total_return_amount
    FROM 
        customer AS c
    LEFT JOIN 
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
WebSalesAndReturns AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COALESCE(CR.total_returns, 0) AS total_returns,
        COALESCE(CR.total_return_amount, 0) AS total_return_amount,
        SUM(ws.ws_net_profit) AS net_profit
    FROM 
        web_sales AS ws
    LEFT JOIN 
        CustomerReturns AS CR ON ws.ws_bill_customer_sk = CR.c_customer_sk
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_web_site_sk
)
SELECT 
    w.web_site_id,
    ws.total_orders,
    ws.total_returns,
    ws.total_return_amount,
    ws.net_profit,
    CASE 
        WHEN ws.net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profitability_status
FROM 
    WebSalesAndReturns ws
JOIN 
    web_site w ON ws.ws_web_site_sk = w.web_site_sk
JOIN 
    TopWebSites tw ON w.web_site_sk = tw.web_site_sk
WHERE 
    ws.total_orders > 10
ORDER BY 
    ws.net_profit DESC;
