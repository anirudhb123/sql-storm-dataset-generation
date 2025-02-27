
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS item_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= 2450000 AND 
        ws.ws_sales_price IS NOT NULL
),
ItemReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_quantity > 0
    GROUP BY 
        wr.wr_item_sk
),
AggregatedSales AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_ext_sales_price) AS total_sales,
        AVG(s.ss_sales_price) AS avg_sales_price,
        SUM(s.ss_ext_discount_amt) AS total_discount,
        CASE 
            WHEN SUM(s.ss_ext_sales_price) > 0 THEN ROUND((SUM(s.ss_ext_discount_amt) / SUM(s.ss_ext_sales_price)) * 100, 2) 
            ELSE NULL 
        END AS discount_percentage
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales)
    GROUP BY 
        s.ss_item_sk
)
SELECT 
    cs.i_item_id,
    cs.i_item_desc,
    COALESCE(ag.total_sales, 0) AS total_sales,
    COALESCE(ag.avg_sales_price, 0) AS avg_sales_price,
    COALESCE(ir.total_returned, 0) AS total_returns,
    ir.return_count,
    CASE 
        WHEN ag.discount_percentage IS NOT NULL AND ag.discount_percentage > 0 
        THEN 'Discounted'
        ELSE 'Non-discounted' 
    END AS sales_type,
    MAX(rs.sales_rank) AS max_rank,
    COUNT(DISTINCT CASE WHEN rs.sales_rank = 1 THEN rs.ws_order_number END) AS top_sales_occurrences
FROM 
    item cs
LEFT JOIN 
    AggregatedSales ag ON cs.i_item_sk = ag.ss_item_sk
LEFT JOIN 
    ItemReturns ir ON cs.i_item_sk = ir.wr_item_sk
LEFT JOIN 
    RankedSales rs ON cs.i_item_sk = rs.ws_item_sk
GROUP BY 
    cs.i_item_id, cs.i_item_desc, ir.return_count, ag.total_sales, ag.avg_sales_price, ag.discount_percentage
HAVING 
    COALESCE(ag.total_sales, 0) > 1000 
    OR COALESCE(ir.total_returned, 0) > 5
ORDER BY 
    total_sales DESC, total_returns ASC, max_rank DESC;
