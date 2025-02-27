
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_refunded
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS total_orders,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_refunded, 0) AS total_refunded,
        COALESCE(sd.total_spent, 0) AS total_spent,
        COALESCE(sd.total_orders, 0) AS total_orders,
        sd.last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.customer_sk
),
FilteredCustomers AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS customer_rank,
        DENSE_RANK() OVER (ORDER BY total_returns DESC) AS returns_rank
    FROM 
        TopCustomers
    WHERE 
        total_spent > 0
        AND total_orders >= 1
)
SELECT 
    c.c_customer_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    f.total_returns,
    f.total_refunded,
    f.total_spent,
    f.total_orders,
    f.last_purchase_date,
    CASE 
        WHEN f.customer_rank <= 10 THEN 'Top Spender'
        ELSE 'Regular'
    END AS customer_type,
    COALESCE(DATEDIFF(CURRENT_DATE, f.last_purchase_date), 9999) AS days_since_last_purchase
FROM 
    FilteredCustomers f
JOIN 
    customer c ON f.c_customer_sk = c.c_customer_sk
WHERE 
    f.customer_rank <= 20
ORDER BY 
    f.total_spent DESC, 
    f.total_returns DESC;
