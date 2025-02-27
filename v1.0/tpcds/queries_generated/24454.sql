
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_profit_per_item
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451916 AND 2452022
), 
HighProfitItems AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_net_profit,
        r.total_profit_per_item
    FROM 
        RankedSales r
    WHERE 
        r.profit_rank <= 5
), 
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returns,
        COUNT(DISTINCT cr.returning_cdemo_sk) AS unique_customers
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
), 
ItemDemographics AS (
    SELECT 
        i.i_item_sk,
        d.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    GROUP BY 
        i.i_item_sk, d.cd_gender
)
SELECT 
    hpi.ws_item_sk,
    hpi.total_profit_per_item,
    cd.unique_customers,
    SUM(id.customer_count) AS total_customers
FROM 
    HighProfitItems hpi
FULL OUTER JOIN 
    CustomerReturns cd ON hpi.ws_order_number = cd.returning_customer_sk
FULL OUTER JOIN 
    ItemDemographics id ON hpi.ws_item_sk = id.i_item_sk
WHERE 
    (cd.total_returns IS NOT NULL OR hpi.total_profit_per_item > 1000)
    AND (id.cd_gender IS NULL OR id.cd_gender = 'M')
GROUP BY 
    hpi.ws_item_sk, cd.unique_customers, hpi.total_profit_per_item
HAVING 
    COALESCE(SUM(id.customer_count), 0) > 10
ORDER BY 
    hpi.ws_item_sk DESC;
