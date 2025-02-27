
WITH RankedReturns AS (
    SELECT 
        sr_refunded_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(sr_return_quantity) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY sr_refunded_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_refunded_customer_sk
),
RecentSales AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_ship_customer_sk
),
TopCustomers AS (
    SELECT 
        rr.sr_refunded_customer_sk,
        rr.total_return_amt,
        rs.total_sales,
        rs.order_count,
        (COALESCE(rs.total_sales, 0) - rr.total_return_amt) AS net_revenue
    FROM 
        RankedReturns rr
    LEFT JOIN 
        RecentSales rs ON rr.sr_refunded_customer_sk = rs.ws_ship_customer_sk
    WHERE 
        rr.rn <= 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(tc.net_revenue, 0) AS net_revenue,
    COALESCE(tc.return_count, 0) AS return_count,
    COALESCE(tc.order_count, 0) AS order_count,
    CASE 
        WHEN tc.net_revenue > 0 THEN 'Positive'
        WHEN tc.net_revenue < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS revenue_status
FROM 
    customer c
LEFT JOIN 
    TopCustomers tc ON c.c_customer_sk = tc.sr_refunded_customer_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL
ORDER BY 
    net_revenue DESC;
