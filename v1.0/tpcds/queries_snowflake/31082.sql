
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i_item_sk, 
        i_item_id, 
        i_product_name, 
        i_manufact, 
        i_current_price
    FROM 
        item
    WHERE 
        i_current_price IS NOT NULL
    UNION ALL
    SELECT 
        ih.i_item_sk, 
        ih.i_item_id, 
        ih.i_product_name, 
        ih.i_manufact, 
        ihier.i_current_price * 0.9  
    FROM 
        item ih
    JOIN 
        ItemHierarchy ihier ON ihier.i_item_sk = ih.i_item_sk
),
SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sold
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 10000
    GROUP BY 
        ws_item_sk
),
ReturnedData AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_returned
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
AggregatedData AS (
    SELECT 
        item.i_item_sk, 
        item.i_product_name, 
        COALESCE(SD.total_sold, 0) AS total_sold,
        COALESCE(RD.total_returned, 0) AS total_returned,
        item.i_current_price,
        item.i_manufact,
        (COALESCE(SD.total_sold, 0) - COALESCE(RD.total_returned, 0)) * item.i_current_price AS net_revenue,
        ROW_NUMBER() OVER (ORDER BY ((COALESCE(SD.total_sold, 0) - COALESCE(RD.total_returned, 0)) * item.i_current_price) DESC) AS rank
    FROM 
        item
    LEFT JOIN 
        SalesData SD ON item.i_item_sk = SD.ws_item_sk
    LEFT JOIN 
        ReturnedData RD ON item.i_item_sk = RD.wr_item_sk
    GROUP BY 
        item.i_item_sk, 
        item.i_product_name, 
        item.i_current_price, 
        item.i_manufact, 
        SD.total_sold, 
        RD.total_returned
)
SELECT 
    a.i_item_sk,
    a.i_product_name,
    a.total_sold,
    a.total_returned,
    a.net_revenue,
    IH.i_current_price AS adjusted_price
FROM 
    AggregatedData a
JOIN 
    ItemHierarchy IH ON a.i_item_sk = IH.i_item_sk
WHERE 
    a.net_revenue > 1000 AND 
    (a.total_sold - a.total_returned) > 50
ORDER BY 
    a.rank
LIMIT 100;
