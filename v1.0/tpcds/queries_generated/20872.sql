
WITH RECURSIVE SalesWithPrevious AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS order_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
), SalesSummary AS (
    SELECT 
        swp.ws_item_sk,
        SUM(swp.ws_quantity) AS total_quantity,
        SUM(swp.ws_sales_price) AS total_sales,
        SUM(swp.ws_sales_price) / SUM(swp.ws_quantity) AS avg_price,
        COALESCE(MAX(ws_sales_price) OVER (PARTITION BY swp.ws_item_sk ORDER BY order_rank ROWS BETWEEN 1 PRECEDING AND CURRENT ROW), 0) AS prev_price,
        COUNT(swp.order_rank) AS number_of_sales
    FROM 
        SalesWithPrevious swp
    GROUP BY 
        swp.ws_item_sk
), ItemReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
), FinalReport AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_price,
        ir.total_returned,
        ir.total_returned_amt,
        CASE 
            WHEN ir.total_returned IS NULL THEN 'No Returns'
            WHEN ir.total_returned > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status,
        CASE 
            WHEN ss.avg_price IS NULL OR ss.avg_price = 0 THEN 0
            ELSE (ss.total_sales - ir.total_returned_amt) / ss.avg_price
        END AS effective_sales
    FROM 
        SalesSummary ss
    LEFT JOIN 
        ItemReturns ir ON ss.ws_item_sk = ir.wr_item_sk
)
SELECT 
    fr.ws_item_sk,
    fr.total_quantity,
    fr.total_sales,
    fr.avg_price,
    CASE 
        WHEN fr.effective_sales IS NULL THEN 'NA'
        ELSE ROUND(fr.effective_sales, 2)
    END AS round_effective_sales,
    CASE 
        WHEN fr.prev_price IS NULL THEN 'Price Not Available'
        WHEN fr.prev_price < fr.avg_price THEN 'Price Increased'
        ELSE 'Price Decreased'
    END AS price_trend
FROM 
    FinalReport fr
WHERE 
    fr.total_quantity > 0
ORDER BY 
    fr.total_quantity DESC
FETCH FIRST 10 ROWS ONLY
```
