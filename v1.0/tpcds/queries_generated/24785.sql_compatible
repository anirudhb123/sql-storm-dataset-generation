
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        ss_sold_date_sk,
        ss_ticket_number,
        ss_quantity,
        ss_net_paid,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY ss_sold_date_sk DESC) AS date_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MIN(inv_date_sk) FROM inventory WHERE inv_quantity_on_hand > 0)
),
ReturnSummary AS (
    SELECT 
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
SalesWithReturns AS (
    SELECT 
        r.ss_store_sk,
        r.ss_item_sk,
        r.ss_sold_date_sk,
        r.ss_net_paid,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
        CASE
            WHEN r.ss_net_paid - COALESCE(rs.total_returned_amount, 0) < 0 THEN 'Negative Profit'
            WHEN r.ss_net_paid < 500 THEN 'Low Profit'
            ELSE 'Normal Profit'
        END AS profit_category
    FROM 
        RankedSales r
    LEFT JOIN 
        ReturnSummary rs ON r.ss_store_sk = rs.sr_store_sk
)
SELECT 
    s.ss_store_sk,
    s.ss_item_sk,
    SUM(s.ss_quantity) AS total_quantity_sold,
    SUM(s.ss_net_paid) AS total_net_paid,
    AVG(s.total_returned_quantity) AS avg_returned_quantity,
    STRING_AGG(DISTINCT s.profit_category) AS profit_categories
FROM 
    SalesWithReturns s
WHERE 
    s.date_rank = 1
GROUP BY 
    s.ss_store_sk, s.ss_item_sk
HAVING 
    SUM(s.ss_quantity) > (
        SELECT AVG(total_quantity)
        FROM (
            SELECT 
                ss_store_sk, 
                SUM(ss_quantity) AS total_quantity
            FROM 
                store_sales
            GROUP BY 
                ss_store_sk
        ) AS subquery
    )
ORDER BY 
    s.ss_store_sk, total_net_paid DESC
LIMIT 100 OFFSET 50;
