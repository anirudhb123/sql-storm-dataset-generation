
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS sales_rank,
        COALESCE(ws.ws_ext_discount_amt, 0) AS discount_amt
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sales_price > 0
),
CustomerReturns AS (
    SELECT 
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        web_returns AS wr
    GROUP BY 
        wr.wr_order_number, 
        wr.wr_item_sk
),
HighReturnItems AS (
    SELECT 
        cr.wr_item_sk,
        COUNT(DISTINCT cr.wr_order_number) AS return_count
    FROM 
        CustomerReturns cr
    WHERE 
        cr.total_returns > (SELECT AVG(total_returns) FROM CustomerReturns)
    GROUP BY 
        cr.wr_item_sk
),
BestSellingAsserts AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_net_profit) AS total_net_profit,
        COUNT(*) AS total_sales
    FROM 
        web_sales s
    LEFT JOIN 
        HighReturnItems hri ON s.ws_item_sk = hri.wr_item_sk
    WHERE 
        hri.wr_item_sk IS NULL -- Excluding high return items
    GROUP BY 
        s.ws_item_sk
    HAVING 
        total_sales > 1 -- Only items sold more than once
),
FinalResults AS (
    SELECT 
        rss.ws_item_sk,
        rss.total_sales,
        COALESCE(rs.ws_net_profit, 0) AS estimated_profit,
        (rss.total_sales * 0.05) AS estimated_extra_cost
    FROM 
        BestSellingAsserts rss 
    LEFT JOIN 
        RankedSales rs ON rss.ws_item_sk = rs.ws_item_sk AND rs.sales_rank = 1
)
SELECT 
    f.ws_item_sk,
    f.total_sales,
    f.estimated_profit,
    f.estimated_extra_cost,
    CASE 
        WHEN f.estimated_profit < 0 THEN 'Loss'
        WHEN f.estimated_profit BETWEEN 0 AND 100 THEN 'Low Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM 
    FinalResults f
WHERE 
    f.total_sales > (SELECT AVG(total_sales) FROM BestSellingAsserts)
ORDER BY 
    f.estimated_profit DESC NULLS LAST;
