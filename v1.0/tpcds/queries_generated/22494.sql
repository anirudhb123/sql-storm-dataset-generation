
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        RANK() OVER (ORDER BY ws.ws_sales_price DESC) AS rank_price
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk > 100 AND
        ws.ws_net_profit IS NOT NULL
),
HighProfit AS (
    SELECT
        rs.web_site_sk,
        rs.ws_item_sk,
        rs.ws_net_profit
    FROM
        RankedSales rs
    WHERE
        rs.rank_profit <= 3
),
SalesEstimations AS (
    SELECT 
        coalesce(AVG(cf.avg_profit), 0) AS estimated_profit,
        s.s_store_sk,
        s.s_store_name
    FROM 
        store s
    LEFT JOIN (
        SELECT 
            sw1.s_store_sk, 
            AVG(sw1.ws_net_profit) AS avg_profit 
        FROM 
            web_sales sw1 
        WHERE 
            sw1.ws_net_profit > (SELECT AVG(ws_net_profit) FROM web_sales)
        GROUP BY 
            sw1.s_store_sk
    ) AS cf ON s.s_store_sk = cf.s_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
),
CombinedResults AS (
    SELECT 
        hp.web_site_sk,
        hp.ws_item_sk,
        hp.ws_net_profit,
        se.estimated_profit
    FROM 
        HighProfit hp
    INNER JOIN SalesEstimations se ON hp.web_site_sk = se.s_store_sk
)
SELECT 
    cr.web_site_sk,
    cr.ws_item_sk,
    cr.ws_net_profit,
    cr.estimated_profit,
    CASE 
        WHEN cr.ws_net_profit > cr.estimated_profit THEN 'Above Average'
        WHEN cr.ws_net_profit < cr.estimated_profit THEN 'Below Average'
        ELSE 'Average'
    END AS profit_comparison
FROM 
    CombinedResults cr
WHERE 
    EXISTS (
        SELECT 1
        FROM customer_demographics cd
        WHERE cd.cd_dep_count > 2
        AND cd.cd_credit_rating IS NOT NULL
    )
ORDER BY cr.ws_net_profit DESC, cr.estimated_profit ASC
LIMIT 10;
