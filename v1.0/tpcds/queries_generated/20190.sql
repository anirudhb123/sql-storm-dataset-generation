
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_by_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(wr.wr_item_sk) AS total_returns,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
SalesWithReturns AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.avg_return_amt, 0) AS avg_return_amt,
        CASE 
            WHEN COALESCE(cr.total_returns, 0) > 0 THEN 
                ROUND((rs.total_quantity * 1.0) / NULLIF(cr.total_returns, 0), 2) 
            ELSE 0 
        END AS return_rate
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_item_sk = cr.wr_returning_customer_sk
)
SELECT 
    gw.greatest_item AS item_id,
    gw.total_quantity,
    gw.total_returns,
    gw.return_rate
FROM (
    SELECT 
        ws.ws_item_sk AS greatest_item,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(COALESCE(cr.total_returns, 0)) AS total_returns,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        web_sales ws
    LEFT JOIN 
        CustomerReturns cr ON cr.wr_returning_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2021) 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
) gw
WHERE 
    gw.total_net_paid > (SELECT AVG(ws_net_paid) FROM web_sales) 
    AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = gw.greatest_item AND inv.inv_quantity_on_hand = 0
    )
ORDER BY 
    gw.return_rate DESC
LIMIT 10;
