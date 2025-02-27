
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND dd.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        ws.web_site_id
),
CustomerReturns AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM
        web_returns wr
    JOIN 
        customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    GROUP BY 
        wr.refunded_customer_sk
),
TopWebsites AS (
    SELECT 
        web_site_id 
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    ws.web_site_id,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt
FROM 
    TopWebsites ws
LEFT JOIN 
    RankedSales cs ON ws.web_site_id = cs.web_site_id
LEFT JOIN 
    CustomerReturns cr ON cr.refunded_customer_sk IN (
        SELECT DISTINCT c.c_customer_sk 
        FROM customer c
        JOIN web_sales ws2 ON c.c_customer_sk = ws2.ws_bill_customer_sk
        WHERE ws2.ws_web_site_sk = ws.web_site_id
    )
ORDER BY 
    total_sales DESC, total_orders DESC;
