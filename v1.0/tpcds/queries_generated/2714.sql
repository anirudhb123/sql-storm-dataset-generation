
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesStats AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.bill_customer_sk
),
ReturnsStats AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_net_loss) AS total_returned_loss
    FROM 
        web_returns AS wr
    GROUP BY 
        wr.refunded_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_purchase_estimate,
    ss.total_quantity,
    ss.total_net_profit,
    COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(rs.total_returned_loss, 0) AS total_returned_loss,
    CASE 
        WHEN ss.total_net_profit > 1000 THEN 'High Value Customer'
        WHEN ss.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    CustomerStats AS cs
JOIN 
    SalesStats AS ss ON cs.c_customer_sk = ss.bill_customer_sk
LEFT JOIN 
    ReturnsStats AS rs ON cs.c_customer_sk = rs.refunded_customer_sk
WHERE 
    cs.purchase_rank <= 10
ORDER BY 
    cs.cd_gender, 
    cs.cd_purchase_estimate DESC;
