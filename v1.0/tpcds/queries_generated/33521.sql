
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_ship_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_net_paid > 0
), 
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
), 
ItemSales AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_current_price,
        i_category,
        COALESCE(SUM(ws_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(ws_net_paid), 0) AS total_sales_amount
    FROM 
        item
    LEFT JOIN 
        web_sales ON i_item_sk = ws_item_sk
    GROUP BY 
        i_item_sk, i_item_id, i_current_price, i_category
), 
SalesAnalysis AS (
    SELECT 
        i.item_id,
        i.current_price,
        s.total_quantity_sold,
        s.total_sales_amount,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
        (CASE 
            WHEN s.total_quantity_sold > 0 THEN (r.total_returned_amount / s.total_sales_amount) * 100 
            ELSE NULL 
         END) AS return_rate
    FROM 
        ItemSales s
    LEFT JOIN 
        CustomerReturns r ON s.i_item_sk = r.wr_item_sk
    JOIN 
        item i ON s.i_item_sk = i.i_item_sk
), 
PerformanceMetrics AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_sales_amount DESC) AS rank_by_sales,
        RANK() OVER (PARTITION BY i_category ORDER BY total_quantity_sold DESC) AS rank_within_category
    FROM 
        SalesAnalysis
)

SELECT
    i.item_id,
    p.current_price,
    p.total_quantity_sold,
    p.total_sales_amount,
    p.total_returns,
    p.total_returned_amount,
    p.return_rate,
    DENSE_RANK() OVER (ORDER BY p.return_rate DESC NULLS LAST) AS return_rate_rank,
    (SELECT COUNT(DISTINCT ii.item_id) FROM item ii WHERE ii.i_category = p.i_category) AS total_category_items
FROM 
    PerformanceMetrics p
WHERE 
    p.return_rate > 5 OR p.total_sales_amount > (SELECT AVG(total_sales_amount) FROM PerformanceMetrics)
ORDER BY 
    return_rate_rank, total_sales_amount DESC;
