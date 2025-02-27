
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_web_return_amt,
        COUNT(DISTINCT wr_order_number) AS web_return_count,
        AVG(wr_return_quantity) AS avg_web_return_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
RA AS (
    SELECT 
        COALESCE(cr.returning_customer_sk, wr.returning_customer_sk) AS customer_sk,
        COALESCE(cr.total_return_amt, 0) + COALESCE(wr.total_web_return_amt, 0) AS total_combined_return_amt,
        COALESCE(cr.return_count, 0) + COALESCE(wr.web_return_count, 0) AS total_returns_count,
        COALESCE(cr.avg_return_quantity, 0) + COALESCE(wr.avg_web_return_quantity, 0) AS total_avg_return_qty
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        WebReturns wr ON cr.sr_customer_sk = wr.wr_returning_customer_sk
),
SalesData AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_paid_inc_ship) AS total_sales_amt
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(r.total_combined_return_amt, 0) AS combined_return_amt,
    COALESCE(r.total_returns_count, 0) AS combined_return_count,
    COALESCE(r.total_avg_return_qty, 0) AS combined_avg_return_qty,
    s.total_sales AS total_sales_count,
    s.total_sales_amt AS total_sales_amount,
    CASE 
        WHEN s.total_sales_amt > 0 
        THEN ROUND((COALESCE(r.total_combined_return_amt, 0) / s.total_sales_amt) * 100, 2)
        ELSE NULL
    END AS return_percentage,
    CASE 
        WHEN s.total_sales_count IS NULL THEN 'No Sales'
        ELSE 'Active Customer'
    END AS customer_status
FROM 
    SalesData s
LEFT JOIN 
    RA r ON s.c_customer_sk = r.customer_sk
JOIN 
    customer c ON c.c_customer_sk = s.c_customer_sk
WHERE 
    (c.c_birth_month = 12 AND c.c_birth_day BETWEEN 24 AND 31)
    OR EXISTS (
        SELECT 1
        FROM customer_demographics cd
        WHERE cd.cd_demo_sk = c.c_current_cdemo_sk 
        AND cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
    )
ORDER BY 
    return_percentage DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
