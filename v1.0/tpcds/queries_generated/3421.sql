
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
        AND ws.ws_sales_price IS NOT NULL
),
TotalSales AS (
    SELECT 
        s_store_sk,
        SUM(ss_ext_sales_price) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
),
TopItems AS (
    SELECT 
        item_sk,
        SUM(ws_quantity) AS total_quantity
    FROM 
        SalesData
    WHERE 
        rank <= 5
    GROUP BY 
        item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        COUNT(DISTINCT i.i_brand) AS unique_brands,
        AVG(i.i_current_price) AS avg_price
    FROM 
        item i
    JOIN 
        TopItems ti ON i.i_item_sk = ti.item_sk
    GROUP BY 
        i.i_item_id
)

SELECT 
    w.w_warehouse_name,
    ts.total_sales,
    id.unique_brands,
    id.avg_price
FROM 
    TotalSales ts
LEFT JOIN 
    warehouse w ON ts.s_store_sk = w.w_warehouse_sk
JOIN 
    ItemDetails id ON ts.s_store_sk = id.i_item_sk
WHERE 
    ts.total_sales > (SELECT AVG(total_sales) FROM TotalSales)
ORDER BY 
    ts.total_sales DESC
LIMIT 10;
