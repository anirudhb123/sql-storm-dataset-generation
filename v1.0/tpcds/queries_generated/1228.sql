
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        MAX(ws.ws_net_paid_inc_tax) AS max_sold_price,
        MIN(ws.ws_net_paid_inc_tax) AS min_sold_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        sd.max_sold_price,
        sd.min_sold_price
    FROM 
        SalesData sd
    WHERE 
        sd.rank <= 10
),
CustomerReturns AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.return_quantity) AS total_returned,
        SUM(wr.return_amt) AS total_return_amount
    FROM 
        web_returns wr
    JOIN 
        customer c ON wr.refunded_customer_sk = c.c_customer_sk
    GROUP BY 
        wr.refunded_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ti.total_quantity,
    ti.total_profit,
    cr.total_returned,
    cr.total_return_amount,
    CASE 
        WHEN cr.total_returned IS NULL THEN '0'
        ELSE CAST(cr.total_returned AS VARCHAR)
    END AS returned_count_display,
    CASE 
        WHEN cr.total_return_amount IS NULL THEN '0.00'
        ELSE TO_CHAR(cr.total_return_amount, 'FM999999999.00')
    END AS return_amount_display
FROM 
    customer c
LEFT JOIN 
    TopItems ti ON c.c_customer_sk = ti.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.refunded_customer_sk
ORDER BY 
    ti.total_profit DESC NULLS LAST;
