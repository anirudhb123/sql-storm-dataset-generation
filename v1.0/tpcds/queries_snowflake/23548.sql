
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_sales_price, 
        ws_quantity, 
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        ws_net_paid,
        CASE 
            WHEN ws_net_paid < 0 THEN 'Negative'
            WHEN ws_net_paid BETWEEN 0 AND 100 THEN 'Low'
            WHEN ws_net_paid BETWEEN 101 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS payment_category
    FROM 
        web_sales 
    WHERE 
        ws_ship_date_sk BETWEEN 1000 AND 5000
),
FilteredReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns 
    GROUP BY 
        wr_item_sk
),
FinalAnalysis AS (
    SELECT 
        RS.ws_item_sk,
        RS.ws_sales_price,
        RS.price_rank,
        COALESCE(FR.total_returns, 0) AS total_returns,
        COALESCE(FR.total_return_amount, 0) AS total_return_amount,
        RS.payment_category
    FROM 
        RankedSales RS
    LEFT JOIN 
        FilteredReturns FR ON RS.ws_item_sk = FR.wr_item_sk
    WHERE 
        RS.price_rank = 1 
        AND RS.ws_quantity > (SELECT AVG(ws_quantity) FROM web_sales WHERE ws_sales_price > 0)
)
SELECT 
    FA.ws_item_sk,
    FA.ws_sales_price,
    FA.total_returns,
    FA.total_return_amount,
    FA.payment_category,
    CASE 
        WHEN FA.total_return_amount IS NULL THEN 'No Returns'
        WHEN FA.total_returns = 0 THEN 'Never Returned'
        ELSE 'Returned'
    END AS return_status,
    SUBSTRING(CAST(FA.ws_item_sk AS CHAR), 1, 5) AS short_item_id
FROM 
    FinalAnalysis FA
ORDER BY 
    FA.total_return_amount DESC,
    FA.ws_sales_price;
