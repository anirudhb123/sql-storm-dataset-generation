
WITH CustomerReturns AS (
    SELECT 
        r_reason.r_reason_desc AS return_reason,
        COUNT(DISTINCT wr_returning_customer_sk) AS return_count,
        SUM(wr_return_amt) AS total_return_amount,
        AVG(wr_return_quantity) AS avg_return_quantity
    FROM 
        web_returns wr
    JOIN 
        reason r_reason ON wr.wr_reason_sk = r_reason.r_reason_sk
    WHERE 
        wr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        r_reason.r_reason_desc
),
PopularItems AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        i.i_item_id
    HAVING 
        SUM(ws.ws_net_profit) > 10000
),
ReturnRate AS (
    SELECT 
        ci.i_item_id,
        COALESCE(CAST(COUNT(cr.return_reason) AS DECIMAL) / NULLIF(total_sales.total_sales_quantity, 0), 0) AS return_rate
    FROM 
        PopularItems total_sales
    LEFT JOIN 
        CustomerReturns cr ON cr.return_reason = 'Damaged Merchandise'
    ON 
        ci.i_item_id = cr.return_reason
    GROUP BY 
        ci.i_item_id
)
SELECT 
    p.return_reason,
    p.i_item_id,
    r.return_rate
FROM 
    CustomerReturns p
JOIN 
    ReturnRate r ON p.return_reason = r.return_reason
ORDER BY 
    p.return_count DESC, r.return_rate DESC
LIMIT 10;
