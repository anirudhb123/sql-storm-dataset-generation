
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
        AND i.i_rec_start_date <= CURRENT_DATE
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= CURRENT_DATE)
    GROUP BY 
        ws.ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price
    FROM 
        item i
    WHERE 
        i.i_current_price = (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_rec_start_date <= CURRENT_DATE)
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        id.i_item_desc
    FROM 
        SalesData sd
    JOIN 
        ItemDetails id ON sd.ws_item_sk = id.i_item_sk
    WHERE 
        sd.rank <= 5
)
SELECT 
    ts.ws_item_sk,
    ts.i_item_desc,
    COALESCE(ts.total_quantity, 0) AS net_quantity_sold,
    COALESCE(ts.total_net_paid, 0) AS net_revenue
FROM 
    TopSales ts
LEFT JOIN 
    store_sales ss ON ts.ws_item_sk = ss.ss_item_sk AND ss.ss_sold_date_sk = (
        SELECT MAX(ss2.ss_sold_date_sk)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = ts.ws_item_sk
    )
WHERE 
    ts.total_net_paid IS NOT NULL
ORDER BY 
    net_revenue DESC
LIMIT 10;
