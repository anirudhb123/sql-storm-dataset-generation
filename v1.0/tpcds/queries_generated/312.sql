
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_ext_sales_price,
        rs.ws_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank = 1
),
AggregateData AS (
    SELECT 
        i.i_category,
        SUM(ts.ws_net_profit) AS total_profit,
        COUNT(ts.ws_order_number) AS total_orders,
        AVG(ts.ws_sales_price) AS avg_sales_price
    FROM 
        TopSales ts
    JOIN 
        item i ON ts.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_category
)
SELECT 
    ad.i_category,
    ad.total_profit,
    ad.total_orders,
    ad.avg_sales_price,
    COALESCE(NULLIF(ad.total_profit, 0), 'No profits') AS profit_status
FROM 
    AggregateData ad
LEFT JOIN 
    customer_demographics cd ON ad.total_orders >= cd.cd_purchase_estimate
WHERE 
    cd.cd_marital_status = 'M'
ORDER BY 
    ad.total_profit DESC
LIMIT 10;
