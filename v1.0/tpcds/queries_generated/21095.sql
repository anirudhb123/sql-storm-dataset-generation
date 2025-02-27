
WITH RECURSIVE ExpensiveItems AS (
    SELECT 
        i_item_sk, 
        i_item_id, 
        i_current_price,
        CAST(i_item_desc AS VARCHAR(200)) AS detailed_desc,
        ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY i_current_price DESC) AS rank
    FROM 
        item
    WHERE 
        i_current_price > (SELECT AVG(i_current_price) FROM item)
), 
HighValueReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT sr_return_time_sk) AS number_of_returns
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
    HAVING 
        COUNT(*) > 1
), 
HighReturnItems AS (
    SELECT 
        i.i_item_id, 
        e.i_current_price, 
        hvr.total_return_amt,
        hvr.number_of_returns,
        (e.i_current_price - hvr.total_return_amt / NULLIF(hvr.number_of_returns, 0)) AS effective_price
    FROM 
        HighValueReturns hvr 
    JOIN 
        item i ON i.i_item_sk = hvr.sr_item_sk
    JOIN 
        ExpensiveItems e ON e.i_item_sk = i.i_item_sk
    WHERE 
        effective_price < 0 
        OR (e.i_current_price - hvr.total_return_amt / NULLIF(hvr.number_of_returns, 0)) < 0
), 
PopularWebReturns AS (
    SELECT 
        wr_item_sk, 
        COUNT(*) AS return_count 
    FROM 
        web_returns 
    GROUP BY 
        wr_item_sk 
    HAVING 
        COUNT(*) > (SELECT AVG(return_count) FROM (SELECT COUNT(*) AS return_count FROM web_returns GROUP BY wr_item_sk) AS sub)
) 
SELECT 
    hi.i_item_id,
    hi.effective_price,
    wb.return_count,
    CASE 
        WHEN hi.effective_price IS NULL THEN 'Price Not Available'
        ELSE 'Price Available'
    END AS price_status,
    CASE 
        WHEN hi.effective_price < 0 AND wb.return_count > 0 THEN 'Highly Undesirable'
        ELSE 'Generally Acceptable'
    END AS item_status
FROM 
    HighReturnItems hi 
FULL OUTER JOIN 
    PopularWebReturns wb ON hi.i_item_id = wb.wr_item_sk
ORDER BY 
    hi.effective_price DESC NULLS LAST, 
    wb.return_count DESC;
