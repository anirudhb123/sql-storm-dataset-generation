
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_order_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerPurchases AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        AVG(ws_quantity) AS avg_order_quantity
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.total_returns, 0) AS returns,
        COALESCE(cp.total_orders, 0) AS orders,
        COALESCE(cr.total_return_amount, 0) AS return_amount,
        COALESCE(cp.total_spent, 0) AS spent,
        COALESCE(cr.avg_return_quantity, 0) AS avg_return_qty,
        COALESCE(cp.avg_order_quantity, 0) AS avg_order_qty
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN CustomerPurchases cp ON c.c_customer_sk = cp.ws_bill_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.orders,
    cd.spent,
    cd.returns,
    cd.return_amount,
    cd.avg_order_qty,
    cd.avg_return_qty,
    CASE 
        WHEN cd.spent > 1000 THEN 'High Value'
        WHEN cd.spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_category
FROM CustomerDetails cd
WHERE cd.orders > 10
  AND cd.returns < 5
  AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
ORDER BY cd.spent DESC;
