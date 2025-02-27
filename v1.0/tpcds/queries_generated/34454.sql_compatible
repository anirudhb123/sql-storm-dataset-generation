
WITH RECURSIVE CustomerReturnCTE AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopReturningCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cr.total_return_quantity,
        cr.total_return_amt_inc_tax
    FROM 
        CustomerReturnCTE cr
    JOIN 
        customer c ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.rn <= 10
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_order_count,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_net_paid_inc_tax) AS avg_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.c_email_address,
    COALESCE(sd.total_order_count, 0) AS total_orders,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit,
    d.d_year,
    d.d_month_seq,
    SUM(p.p_cost) AS total_promotion_cost
FROM 
    TopReturningCustomers tc
LEFT JOIN 
    SalesData sd ON sd.ws_bill_customer_sk = tc.c_customer_sk
LEFT JOIN 
    promotion p ON p.p_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_bill_customer_sk = tc.c_customer_sk
    )
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_sk)
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = tc.c_customer_sk
WHERE 
    (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F') 
    AND cd.cd_purchase_estimate > 1000
GROUP BY 
    tc.c_customer_sk, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.c_email_address,
    sd.total_order_count,
    sd.total_net_profit,
    d.d_year,
    d.d_month_seq
ORDER BY 
    total_net_profit DESC;
