
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.store_sk,
        SUM(sr.return_quantity) AS total_returned_qty,
        SUM(sr.return_amt_inc_tax) AS total_returned_amt,
        c.c_demo_sk,
        c.c_first_name,
        c.c_last_name
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.s_customer_sk = c.c_customer_sk
    GROUP BY 
        sr.returned_date_sk, sr.store_sk, c.c_demo_sk, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        ws.sold_date_sk,
        ws.web_site_sk,
        SUM(ws.quantity) AS total_sold_qty,
        SUM(ws.net_paid_inc_tax) AS total_net_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.sold_date_sk, ws.web_site_sk
),
CombinedData AS (
    SELECT 
        d.d_date AS sale_date,
        cs.store_sk,
        c.customer_name,
        COALESCE(cr.total_returned_qty, 0) AS total_returned_qty,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
        COALESCE(ss.total_sold_qty, 0) AS total_sold_qty,
        COALESCE(ss.total_net_sales, 0) AS total_net_sales
    FROM 
        date_dim d
    LEFT JOIN 
        CustomerReturns cr ON d.d_date_sk = cr.returned_date_sk
    LEFT JOIN 
        SalesSummary ss ON d.d_date_sk = ss.sold_date_sk
    LEFT JOIN 
        (SELECT 
            c.c_customer_sk,
            CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name
        FROM 
            customer c) AS c ON cr.c_demo_sk = c.c_customer_sk
    WHERE 
        d.d_year = 2023
)
SELECT 
    sale_date,
    store_sk,
    customer_name,
    total_returned_qty,
    total_returned_amt,
    total_sold_qty,
    total_net_sales,
    (total_net_sales - total_returned_amt) AS net_revenue
FROM 
    CombinedData
ORDER BY 
    sale_date, store_sk;
