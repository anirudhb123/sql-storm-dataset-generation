
WITH RECURSIVE SalesCTE (ss_item_sk, total_quantity, total_profit, level) AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit,
        1 AS level
    FROM store_sales
    GROUP BY ss_item_sk
    UNION ALL
    SELECT 
        item.i_item_sk,
        SUM(ss.ss_quantity) + CTE.total_quantity,
        SUM(ss.ss_net_profit) + CTE.total_profit,
        level + 1
    FROM store_sales ss
    JOIN item ON ss.ss_item_sk = item.i_item_sk
    JOIN SalesCTE CTE ON item.i_item_sk = CTE.ss_item_sk
    WHERE level < 5
    GROUP BY item.i_item_sk, CTE.total_quantity, CTE.total_profit, level
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_returned_date_sk) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
ItemReturns AS (
    SELECT 
        ir.ss_item_sk,
        COALESCE(cr.return_count, 0) AS returns,
        COALESCE(cr.total_return_amount, 0) AS total_returns_amt,
        ir.total_quantity,
        ir.total_profit
    FROM SalesCTE ir
    LEFT JOIN CustomerReturns cr ON ir.ss_item_sk = cr.sr_item_sk
),
RankedItems AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
        DENSE_RANK() OVER (ORDER BY total_quantity DESC) AS quantity_rank
    FROM ItemReturns
)
SELECT 
    ss_item_sk AS i_item_sk,
    total_quantity,
    returns,
    total_returns_amt,
    total_profit,
    profit_rank,
    quantity_rank
FROM RankedItems
WHERE returns > 0 AND total_profit > 1000
ORDER BY profit_rank, total_quantity DESC
LIMIT 50;
