
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_quantity DESC) AS quantity_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 100 -- assuming dates correspond to some range
),
FilteredSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_price = 1 AND rs.quantity_rank <= 5
),
ItemReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        COUNT(*) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
ReturnsWithSales AS (
    SELECT 
        fs.ws_order_number,
        fs.ws_item_sk,
        fs.ws_quantity,
        fs.ws_sales_price,
        ir.total_returns,
        ir.return_count,
        CASE 
            WHEN ir.return_count IS NULL THEN 'No Returns'
            WHEN ir.total_returns > (fs.ws_quantity / 2) THEN 'High Return Rate'
            ELSE 'Normal Return Rate' END AS return_analysis
    FROM 
        FilteredSales fs
    LEFT JOIN 
        ItemReturns ir ON fs.ws_item_sk = ir.wr_item_sk
)
SELECT 
    r.ws_order_number,
    r.ws_item_sk,
    r.ws_quantity,
    r.ws_sales_price,
    r.return_analysis,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.return_count, 0) AS return_count,
    CONCAT('Item: ', (SELECT i.i_item_desc FROM item i WHERE i.i_item_sk = r.ws_item_sk)) AS item_description
FROM 
    ReturnsWithSales r
WHERE 
    r.ws_quantity > 10 OR r.return_analysis = 'High Return Rate'
ORDER BY 
    r.ws_sales_price DESC, r.return_analysis;
