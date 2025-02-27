
WITH CustomerPurchaseStats AS (
    SELECT 
        c.c_customer_id, 
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), 

HighSpendingCustomers AS (
    SELECT 
        cps.c_customer_id, 
        cps.total_orders, 
        cps.total_spent,
        DENSE_RANK() OVER (ORDER BY cps.total_spent DESC) AS rank
    FROM 
        CustomerPurchaseStats cps
    WHERE 
        cps.total_orders > 5 AND cps.total_spent > 1000
),

ReturnStats AS (
    SELECT 
        wr.returned_customer_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_returned
    FROM 
        web_returns wr
    GROUP BY 
        wr.returned_customer_sk
),

FinalStats AS (
    SELECT 
        hsc.c_customer_id,
        hsc.total_orders, 
        hsc.total_spent,
        rs.total_returns, 
        rs.total_returned,
        CASE 
            WHEN rs.total_returns IS NULL THEN 'No Returns'
            WHEN rs.total_returns > 0 AND rs.total_returns < 3 THEN 'Low Returns'
            ELSE 'High Returns'
        END AS return_category
    FROM 
        HighSpendingCustomers hsc
    LEFT JOIN 
        ReturnStats rs ON hsc.c_customer_id = rs.returned_customer_sk
)

SELECT 
    f.c_customer_id,
    f.total_orders,
    f.total_spent,
    f.total_returns,
    f.return_category,
    COALESCE(ROUND((f.total_returns::decimal / NULLIF(f.total_orders, 0)) * 100, 2), 0) AS return_rate
FROM 
    FinalStats f
ORDER BY 
    f.total_spent DESC
LIMIT 10;
