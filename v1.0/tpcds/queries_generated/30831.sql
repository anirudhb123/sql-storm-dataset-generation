
WITH RECURSIVE DateCTE AS (
    SELECT d_date_sk, d_date, d_year, 1 AS depth
    FROM date_dim
    WHERE d_date = (SELECT MAX(d_date) FROM date_dim)
    
    UNION ALL
    
    SELECT d.d_date_sk, d.d_date, d.d_year, depth + 1
    FROM date_dim d
    JOIN DateCTE cte ON d.d_date_sk = cte.d_date_sk - 1
    WHERE cte.depth < 10
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
),
SalesSummary AS (
    SELECT 
        d.d_year,
        COALESCE(SUM(i.total_quantity_sold), 0) AS total_quantity,
        COALESCE(SUM(i.total_net_profit), 0) AS total_net_profit,
        CASE 
            WHEN SUM(i.total_quantity_sold) > 1000 THEN 'High'
            WHEN SUM(i.total_quantity_sold) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS sales_category
    FROM DateCTE d
    LEFT JOIN ItemSales i ON d.d_year = i.i_item_sk
    GROUP BY d.d_year
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returned_quantity,
        SUM(sr.sr_return_amt) AS total_returned_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returned_tickets
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
)
SELECT 
    ss.d_year, 
    ss.total_quantity, 
    ss.total_net_profit, 
    ss.sales_category,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
    COALESCE(cr.total_returned_tickets, 0) AS total_returned_tickets
FROM SalesSummary ss
LEFT JOIN CustomerReturns cr ON ss.total_quantity = cr.total_returned_quantity
ORDER BY ss.d_year DESC;
