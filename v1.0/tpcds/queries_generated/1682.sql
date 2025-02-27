
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CD.cd_credit_rating,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_order_number) OVER (PARTITION BY c.c_customer_id) AS unique_orders,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
ReturnStats AS (
    SELECT 
        sr.sr_returned_date_sk,
        COUNT(sr.sr_order_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_returned_date_sk
),
AggregateReturns AS (
    SELECT 
        dr.d_date_id,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount
    FROM 
        date_dim dr
    LEFT JOIN 
        ReturnStats rs ON dr.d_date_sk = rs.sr_returned_date_sk
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.total_profit,
    cs.total_orders,
    ar.total_returns,
    ar.total_return_amount
FROM 
    CustomerStats cs
LEFT JOIN 
    AggregateReturns ar ON ar.total_returns > 0
WHERE 
    cs.total_profit > 5000
    AND cs.cd_gender IS NOT NULL
ORDER BY 
    cs.profit_rank
LIMIT 100;
