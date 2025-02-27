
WITH RankedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rn
    FROM 
        customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_dep_count > 0
        AND ws.ws_sold_date_sk BETWEEN 1 AND 365 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), TopCustomers AS (
    SELECT 
        * 
    FROM 
        RankedSales
    WHERE 
        rn <= 10
), ReturnStats AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    COALESCE(rs.return_count, 0) AS return_count,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN tc.total_sales > 0 THEN ROUND((rs.total_return_amt / tc.total_sales) * 100, 2)
        ELSE 0
    END AS return_rate_percentage
FROM 
    TopCustomers tc
    LEFT JOIN ReturnStats rs ON tc.c_customer_sk = rs.sr_returning_customer_sk
ORDER BY 
    tc.total_sales DESC;
