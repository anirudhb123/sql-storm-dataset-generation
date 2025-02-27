
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
TopSales AS (
    SELECT 
        web_site_sk,
        ws_order_number,
        total_quantity,
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        rk <= 10
),
Returns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
AggregateData AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales,
        COALESCE(SUM(r.total_return_amt), 0) AS total_returns,
        COALESCE(SUM(ws.ws_net_profit), 0) - COALESCE(SUM(r.total_return_amt), 0) AS net_sales
    FROM 
        customer cs
    LEFT JOIN 
        web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        Returns r ON cs.c_customer_sk = r.wr_returning_customer_sk
    WHERE 
        cs.c_birth_year IS NOT NULL AND 
        (cs.c_birth_month IS NULL OR cs.c_birth_month != 0)
    GROUP BY 
        cs.c_customer_sk
)
SELECT 
    ad.c_customer_sk,
    CASE 
        WHEN ad.net_sales > 0 THEN 'Profitable'
        ELSE 'Unprofitable'
    END AS profitability_label,
    STRING_AGG(DISTINCT ws.web_site_id) AS web_site_ids
FROM 
    AggregateData ad
JOIN 
    TopSales ts ON ad.total_sales > ts.total_net_profit
JOIN 
    web_site ws ON ts.web_site_sk = ws.web_site_sk
GROUP BY 
    ad.c_customer_sk, ad.net_sales
ORDER BY 
    ad.net_sales DESC, ad.c_customer_sk
LIMIT 100;
