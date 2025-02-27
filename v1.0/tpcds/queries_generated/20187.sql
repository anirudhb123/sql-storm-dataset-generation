
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_fee) AS total_return_fee,
        COALESCE(SUM(sr_return_quantity), 0) AS total_return_quantity
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
WebReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_item_sk,
        COUNT(wr_order_number) AS total_web_returns,
        SUM(wr_return_amt) AS total_web_return_amount,
        SUM(wr_return_fee) AS total_web_return_fee,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_return_quantity
    FROM web_returns
    GROUP BY wr_returned_date_sk, wr_item_sk
),
CombinedReturns AS (
    SELECT 
        COALESCE(sr.returned_date, wr.returned_date) AS return_date,
        COALESCE(sr.item_sk, wr.item_sk) AS item_sk,
        COALESCE(sr.total_returns, 0) + COALESCE(wr.total_web_returns, 0) AS combined_returns,
        COALESCE(sr.total_return_amount, 0) + COALESCE(wr.total_web_return_amount, 0) AS combined_return_amount,
        COALESCE(sr.total_return_quantity, 0) + COALESCE(wr.total_web_return_quantity, 0) AS combined_return_quantity
    FROM 
        (SELECT DISTINCT return_date AS returned_date, item_sk FROM CustomerReturns) AS sr
    FULL OUTER JOIN
        (SELECT DISTINCT return_date AS returned_date, item_sk FROM WebReturns) AS wr
    ON sr.returned_date = wr.returned_date
    AND sr.item_sk = wr.item_sk
),
RankedReturns AS (
    SELECT 
        return_date,
        item_sk,
        combined_returns,
        combined_return_amount,
        RANK() OVER (PARTITION BY return_date ORDER BY combined_return_amount DESC) AS return_rank
    FROM CombinedReturns
)
SELECT 
    r.return_date,
    i.i_item_id,
    r.combined_returns,
    r.combined_return_amount,
    r.return_rank,
    CASE 
        WHEN r.combined_return_quantity > 100 THEN 'High Returns'
        WHEN r.combined_return_quantity BETWEEN 50 AND 100 THEN 'Moderate Returns'
        ELSE 'Low Returns'
    END AS return_category,
    SUBSTRING(i.i_item_desc, 1, 30) AS short_description,
    CASE 
        WHEN r.return_rank = 1 THEN 'Top Returned Item'
        ELSE NULL
    END AS noteworthy_item
FROM RankedReturns r
JOIN item i ON r.item_sk = i.i_item_sk
WHERE r.return_rank <= 5 OR r.return_rank IS NULL
ORDER BY r.return_date, r.combined_return_amount DESC, r.item_sk;
