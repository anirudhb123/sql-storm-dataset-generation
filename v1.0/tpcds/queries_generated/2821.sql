
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 100  -- Assuming valid date range
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.total_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_returned
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
CustomerReturnStats AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_returned, 0) AS total_returned
    FROM 
        TopCustomers tc
    LEFT JOIN 
        ReturnStats rs ON tc.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    crs.c_customer_sk,
    crs.c_first_name,
    crs.c_last_name,
    crs.total_spent,
    crs.total_orders,
    crs.total_returns,
    crs.total_returned,
    CASE 
        WHEN crs.total_orders > 0 THEN ROUND((crs.total_returned / CAST(crs.total_orders AS DECIMAL)) * 100, 2)
        ELSE NULL 
    END AS return_rate_percentage,
    CASE 
        WHEN crs.total_returned > 100 THEN 'High'
        WHEN crs.total_returned BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS return_segment
FROM 
    CustomerReturnStats crs
ORDER BY 
    crs.total_spent DESC;
