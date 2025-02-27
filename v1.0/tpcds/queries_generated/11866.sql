
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ItemSummary AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_current_price
    FROM 
        item
)
SELECT 
    sd.ws_sold_date_sk,
    is.i_product_name,
    is.i_current_price,
    sd.total_quantity,
    sd.total_sales
FROM 
    SalesData sd
JOIN 
    ItemSummary is ON sd.ws_item_sk = is.i_item_sk
ORDER BY 
    sd.ws_sold_date_sk, total_sales DESC
LIMIT 100;
