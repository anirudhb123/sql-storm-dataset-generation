
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
TopSales AS (
    SELECT 
        web_site_sk,
        web_name,
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank = 1
),
TotalReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned
    FROM 
        catalog_returns cr
    JOIN 
        item i ON cr.cr_item_sk = i.i_item_sk
    WHERE 
        cr.cr_return_amount > 0
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    ts.web_name,
    ts.total_net_profit,
    COALESCE(tr.total_returned, 0) AS total_returns,
    CASE 
        WHEN ts.total_net_profit > 1000 THEN 'High Profit'
        WHEN ts.total_net_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    TopSales ts
LEFT JOIN 
    TotalReturns tr ON ts.web_site_sk = tr.cr_item_sk
WHERE 
    ts.total_net_profit IS NOT NULL
ORDER BY 
    ts.total_net_profit DESC;
