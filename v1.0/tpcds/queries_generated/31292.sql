
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        1 AS level
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk

    UNION ALL

    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) + cte.total_quantity,
        SUM(ws.ws_net_paid) + cte.total_revenue,
        cte.level + 1
    FROM web_sales ws
    JOIN SalesCTE cte ON ws.ws_item_sk = cte.ws_item_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022 AND cte.level < 5
    GROUP BY ws.ws_item_sk, cte.total_quantity, cte.total_revenue
),
CustomerReturns AS (
    SELECT
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT
    s.ws_item_sk,
    COALESCE(ct.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ct.total_revenue, 0) AS total_revenue,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(cr.total_returns, 0) > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    AVG(CASE 
        WHEN dd.d_current_month = 'Y' THEN ws.ws_net_profit
        ELSE NULL
    END) OVER (PARTITION BY s.ws_item_sk) AS avg_profit_last_month
FROM SalesCTE ct
FULL OUTER JOIN CustomerReturns cr ON ct.ws_item_sk = cr.sr_item_sk
JOIN web_sales s ON s.ws_item_sk = COALESCE(ct.ws_item_sk, cr.sr_item_sk)
LEFT JOIN date_dim dd ON s.ws_sold_date_sk = dd.d_date_sk
WHERE ct.total_revenue > 1000 OR cr.total_returns IS NOT NULL
ORDER BY s.ws_item_sk;
