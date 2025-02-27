
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amount) DESC) AS rank_by_amount,
        COUNT(*) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_refunded_cash IS NOT NULL AND
        sr_return_amt > 0
    GROUP BY 
        sr_item_sk, sr_store_sk
),
HighReturnItems AS (
    SELECT DISTINCT
        item.i_item_id,
        item.i_product_name,
        returns.total_returned,
        returns.return_count
    FROM 
        item
    JOIN 
        RankedReturns returns ON item.i_item_sk = returns.sr_item_sk
    WHERE 
        returns.return_count > 5
),
SalesData AS (
    SELECT 
        ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 5000
    GROUP BY 
        ws_item_sk
)
SELECT 
    hi.i_item_id,
    hi.i_product_name,
    COALESCE(sd.total_sales, 0) AS total_sales,
    hi.total_returned,
    hi.return_count,
    (hi.total_returned * 1.0 / NULLIF(sd.total_sales, 0)) AS return_rate,
    DENSE_RANK() OVER (ORDER BY hi.total_returned DESC) as return_rank,
    CASE 
        WHEN (hi.total_returned / NULLIF(sd.total_sales, 0)) > 0.5 THEN 'High'
        WHEN (hi.total_returned / NULLIF(sd.total_sales, 0)) BETWEEN 0.2 AND 0.5 THEN 'Moderate'
        ELSE 'Low'
    END AS return_category
FROM 
    HighReturnItems hi
LEFT JOIN 
    SalesData sd ON hi.i_item_id = sd.ws_item_sk
WHERE 
    (hi.return_count > 10 OR (SELECT COUNT(*) FROM store WHERE s_number_employees > 50) > 5) 
    AND NOT EXISTS (
        SELECT 1 
        FROM promotion 
        WHERE p_item_sk = hi.i_item_id 
        AND p_discount_active = 'Y'
    )
ORDER BY 
    hi.total_returned DESC, hi.i_product_name;
