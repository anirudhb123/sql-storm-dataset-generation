
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 AND
        cd.cd_gender = 'F'
    GROUP BY 
        ws.ws_sold_date_sk
),
warehouse_returns AS (
    SELECT 
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt) AS total_returned_amount
    FROM 
        web_returns wr
    JOIN 
        warehouse w ON wr.wr_call_center_sk = w.w_warehouse_sk
    GROUP BY 
        wr.wr_returned_date_sk
)
SELECT 
    ds.d_date_id,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_net_profit,
    wr.total_returned_quantity,
    wr.total_returned_amount
FROM 
    date_dim ds
LEFT JOIN 
    sales_summary ss ON ds.d_date_sk = ss.ws_sold_date_sk
LEFT JOIN 
    warehouse_returns wr ON ds.d_date_sk = wr.wr_returned_date_sk
WHERE 
    ds.d_year = 2023
ORDER BY 
    ds.d_date_id;
