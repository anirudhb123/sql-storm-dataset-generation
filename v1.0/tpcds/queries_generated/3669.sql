
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2022
        )
),
TopSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 3
),
CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
OverallReturns AS (
    SELECT 
        cr.returning_customer_sk,
        COALESCE(cr.total_return_amt, 0) AS total_customer_return
    FROM 
        (SELECT DISTINCT ws_bill_customer_sk AS returning_customer_sk FROM web_sales) AS rc
    LEFT JOIN 
        CustomerReturns cr ON rc.returning_customer_sk = cr.sr_returning_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ovs.ws_item_sk,
    ovs.ws_net_profit,
    CASE 
        WHEN or.total_customer_return > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    or.total_customer_return
FROM 
    customer c
JOIN 
    TopSales ovs ON c.c_customer_sk = ovs.ws_order_number 
LEFT JOIN 
    OverallReturns or ON c.c_customer_sk = or.returning_customer_sk
ORDER BY 
    ovs.ws_net_profit DESC, 
    or.total_customer_return DESC;
