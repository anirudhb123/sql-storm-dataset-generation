
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ship_mode_sk,
        sm.sm_type,
        DATEADD(DAY, -30, dd.d_date) AS period_start,
        dd.d_date AS period_end,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sold_date_sk DESC) AS order_rank
    FROM 
        web_sales AS ws
    JOIN 
        ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN DATEADD(DAY, -30, GETDATE()) AND GETDATE()
),
returns_data AS (
    SELECT 
        wr.wr_order_number,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        web_returns AS wr
    GROUP BY 
        wr.wr_order_number
),
summary AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_net_paid,
        rd.total_returned,
        rd.total_returned_amt,
        sd.sm_type,
        CASE 
            WHEN rd.total_returned IS NULL THEN 'No Returns'
            WHEN rd.total_returned > 0 THEN 'Returned'
            ELSE 'No Returns'
        END AS return_status
    FROM 
        sales_data AS sd
    LEFT JOIN 
        returns_data AS rd ON sd.ws_order_number = rd.wr_order_number
    WHERE 
        sd.order_rank = 1
)
SELECT 
    sm.sm_type,
    COUNT(*) AS total_orders,
    SUM(ws_net_paid) AS total_sales,
    COALESCE(SUM(CASE WHEN return_status = 'Returned' THEN ws_net_paid END), 0) AS total_returned_sales,
    (SUM(ws_net_paid) - COALESCE(SUM(CASE WHEN return_status = 'Returned' THEN ws_net_paid END), 0)) AS net_sales
FROM 
    summary AS s
JOIN 
    ship_mode AS sm ON s.sm_type = sm.sm_ship_mode_id
GROUP BY 
    sm.sm_type
ORDER BY 
    total_sales DESC;
