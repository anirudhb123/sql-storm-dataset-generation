
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        r.ws_item_sk,
        i.i_item_desc,
        i.i_current_price,
        r.total_quantity,
        r.total_net_profit
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank_profit <= 10
)
SELECT 
    tsi.i_item_desc,
    tsi.total_quantity,
    tsi.total_net_profit,
    CASE 
        WHEN tsi.total_net_profit IS NULL THEN 'No Profit'
        WHEN tsi.total_net_profit > 1000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    TopSellingItems tsi
LEFT JOIN 
    customer c ON c.c_customer_sk = (
        SELECT 
            ws_bill_customer_sk 
        FROM 
            web_sales 
        WHERE 
            ws_item_sk = tsi.ws_item_sk 
        LIMIT 1
    )
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'M' AND
    (cd.cd_marital_status IS NULL OR cd.cd_marital_status = 'S')
ORDER BY 
    tsi.total_net_profit DESC;
