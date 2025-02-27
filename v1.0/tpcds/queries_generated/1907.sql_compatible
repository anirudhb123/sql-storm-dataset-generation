
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
RecentSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_sales) AS total_net_sales,
        COUNT(ws_order_number) AS total_orders
    FROM (
        SELECT 
            ws_bill_customer_sk,
            ws_order_number,
            (ws_sales_price * ws_quantity) - ws_coupon_amt AS ws_net_sales
        FROM web_sales
        WHERE ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    ) AS recent_web_sales
    GROUP BY ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(rs.total_net_sales, 0) AS total_net_sales,
        COALESCE(rs.total_orders, 0) AS total_orders
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN RecentSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    cb.total_returns,
    cb.total_return_amount,
    cb.total_net_sales,
    cb.total_orders,
    CASE 
        WHEN cb.total_net_sales > 10000 THEN 'High Value Customer'
        WHEN cb.total_net_sales BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cb.total_net_sales DESC) AS rank
FROM CombinedData cb
JOIN customer_demographics cd ON cb.c_customer_sk = cd.cd_demo_sk
WHERE cb.total_orders > 0
ORDER BY cd.cd_gender, cb.total_net_sales DESC;
