
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cr.total_returns,
        cr.total_return_amount,
        cr.return_count,
        RANK() OVER (ORDER BY cr.total_return_amount DESC) AS return_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_returns > 0
),
WebSalesSummary AS (
    SELECT 
        ws.ship_mode_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ship_mode_sk
)
SELECT 
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    hrc.c_customer_id,
    hrc.cd_gender,
    hrc.cd_marital_status,
    hrc.total_returns,
    hrc.total_return_amount,
    wss.total_quantity,
    wss.order_count,
    wss.total_profit
FROM 
    warehouse w
LEFT JOIN 
    HighReturnCustomers hrc ON hrc.return_rank <= 100
LEFT JOIN 
    WebSalesSummary wss ON w.w_warehouse_sk = wss.ship_mode_sk
WHERE 
    (w.w_city IS NOT NULL OR w.w_state IS NOT NULL)
    AND (hrc.total_returns IS NOT NULL OR hrc.total_return_amount IS NOT NULL)
ORDER BY 
    hrc.total_return_amount DESC, 
    w.w_warehouse_name;
