
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.net_profit IS NOT NULL
),
SalesSummary AS (
    SELECT 
        RANK() OVER (ORDER BY SUM(ws.net_paid_inc_tax) DESC) AS sales_rank,
        D.d_year,
        SUM(ws.net_paid_inc_tax) AS total_net_paid
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim D ON ws.ws_sold_date_sk = D.d_date_sk
    WHERE 
        D.d_year BETWEEN 2010 AND 2020
    GROUP BY 
        D.d_year
)
SELECT 
    COALESCE(cs.category, 'Unknown') AS category,
    total_sales.total_net_paid,
    AVG(RankSales.net_profit) AS avg_profit,
    SUM(COALESCE(returns.return_quantity, 0)) AS total_returns
FROM 
    (SELECT 
        DISTINCT category
     FROM 
        (SELECT 
            item.i_category AS category 
          FROM 
            item item) AS cat) AS cs
LEFT JOIN 
    (SELECT 
        SUM(ws.net_paid_inc_tax) AS total_net_paid
     FROM 
        web_sales ws
     JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
     GROUP BY 
        i.i_category) AS total_sales ON cs.category = total_sales.category
LEFT JOIN 
    (SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS return_quantity
     FROM 
        store_returns
     GROUP BY 
        sr_item_sk) AS returns ON returns.sr_item_sk = (SELECT i_item_sk FROM item WHERE i_category = cs.category)
LEFT JOIN 
    RankedSales ON RankedSales.web_site_sk = total_sales.web_site_sk
WHERE 
    total_sales.total_net_paid > 1000 AND 
    (avg_profit > (SELECT AVG(net_profit) FROM RankedSales) OR 
     EXISTS (SELECT 1 FROM web_sales ws WHERE ws.ws_item_sk = returns.sr_item_sk AND ws.net_profit < 0))
GROUP BY 
    cs.category, total_sales.total_net_paid
HAVING 
    COUNT(DISTINCT returns.return_quantity) IS NULL OR 
    COUNT(returns.return_quantity) > 5
ORDER BY 
    avg_profit DESC NULLS LAST;
