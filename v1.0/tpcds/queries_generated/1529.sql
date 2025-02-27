
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy BETWEEN 1 AND 3
    GROUP BY 
        ws.web_site_id
),
CustomerReturns AS (
    SELECT 
        wr_returned_customer_sk,
        COUNT(DISTINCT wr_order_number) AS return_count,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returned_customer_sk
),
SalesAndReturns AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_email_address,
        rs.total_sales,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM 
        customer cs
    LEFT JOIN
        (SELECT 
            ws_bill_customer_sk,
            SUM(ws_ext_sales_price) AS total_sales
        FROM 
            web_sales
        GROUP BY 
            ws_bill_customer_sk) AS ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        CustomerReturns cr ON cs.c_customer_sk = cr.wr_returned_customer_sk
)
SELECT 
    sa.c_customer_sk,
    sa.c_email_address,
    sa.total_sales,
    sa.return_count,
    sa.total_return_amount,
    CASE 
        WHEN sa.total_sales IS NULL THEN 'No Sales'
        WHEN sa.return_count > 0 THEN 'Returns Made'
        ELSE 'No Returns'
    END AS return_status,
    RANK() OVER (ORDER BY sa.total_sales DESC) AS customer_sales_rank
FROM 
    SalesAndReturns sa
WHERE 
    sa.total_sales > 1000
ORDER BY 
    customer_sales_rank
FETCH FIRST 100 ROWS ONLY;
