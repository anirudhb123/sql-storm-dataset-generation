
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_profit, 0) AS total_profit,
        COALESCE(sd.order_count, 0) AS order_count
    FROM 
        item i
    LEFT JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
),
CustomerStats AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependencies
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk, cd_gender
),
HighValueItems AS (
    SELECT 
        id.i_item_sk,
        id.i_item_desc,
        id.i_current_price,
        id.i_brand
    FROM 
        ItemDetails id
    WHERE 
        id.total_profit > (
            SELECT AVG(total_profit) * 1.5 
            FROM ItemDetails
        )
)
SELECT 
    hi.i_item_sk,
    hi.i_item_desc,
    hi.i_current_price,
    hi.i_brand,
    cs.cd_gender,
    cs.avg_purchase_estimate,
    cs.total_dependencies
FROM 
    HighValueItems hi
INNER JOIN 
    CustomerStats cs ON hi.i_item_sk IN (
        SELECT sr_item_sk 
        FROM store_returns 
        WHERE sr_return_quantity > 0
    )
ORDER BY 
    hi.total_profit DESC,
    cs.avg_purchase_estimate DESC
LIMIT 10;
