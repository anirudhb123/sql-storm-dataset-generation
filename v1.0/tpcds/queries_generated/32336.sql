
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_item_sk,
        wr_order_number,
        wr_return_quantity,
        wr_return_amt,
        1 AS level
    FROM 
        web_returns
    WHERE 
        wr_return_quantity > 0
    UNION ALL
    SELECT 
        wr_returning_customer_sk,
        wr_item_sk,
        wr_order_number,
        wr_return_quantity + cr_return_quantity,
        wr_return_amt + cr_return_amount,
        level + 1
    FROM 
        CustomerReturns cr
    JOIN 
        catalog_returns wr ON wr_returning_customer_sk = cr.wr_returning_customer_sk 
        AND wr_item_sk = cr.wr_item_sk
    WHERE 
        level < 10
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        DATE(d_date) AS sales_date
    FROM 
        web_sales ws 
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws_bill_customer_sk, DATE(d_date)
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(cr.wr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sd.total_sales), 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    c.c_customer_id,
    cs.total_sales,
    cs.total_returns,
    (cs.total_sales - cs.total_returns) AS net_sales,
    CASE 
        WHEN cs.total_sales > 0 THEN (cs.total_returns::decimal / cs.total_sales) * 100
        ELSE 0 
    END AS return_percentage
FROM 
    CustomerStats cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE 
    cs.total_returns > (SELECT AVG(total_returns) FROM CustomerStats)
ORDER BY 
    return_percentage DESC;
