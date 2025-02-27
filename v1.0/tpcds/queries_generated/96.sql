
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        ranked.total_quantity,
        ranked.total_sales
    FROM 
        RankedSales ranked
    JOIN 
        item ON ranked.ws_item_sk = item.i_item_sk
    WHERE 
        ranked.sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ItemPerformance AS (
    SELECT 
        tsi.i_item_id,
        tsi.i_item_desc,
        tsi.total_quantity,
        tsi.total_sales,
        COALESCE(cr.total_returned, 0) AS total_returned,
        (tsi.total_sales - COALESCE(cr.total_returned, 0)) AS net_sales,
        CASE 
            WHEN (tsi.total_sales - COALESCE(cr.total_returned, 0)) < 0 
            THEN 'Negative Performance' 
            ELSE 'Positive Performance' 
        END AS performance_status
    FROM 
        TopSellingItems tsi
    LEFT JOIN 
        CustomerReturns cr ON tsi.ws_item_sk = cr.sr_item_sk
)
SELECT 
    item_id, 
    item_desc, 
    total_quantity, 
    total_sales, 
    total_returned, 
    net_sales,
    performance_status
FROM 
    ItemPerformance
WHERE 
    performance_status = 'Negative Performance'
ORDER BY 
    net_sales ASC;
