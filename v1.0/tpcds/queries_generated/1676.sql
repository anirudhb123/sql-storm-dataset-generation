
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2022
    GROUP BY
        ws.web_site_sk, ws.web_site_id
),
CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(wr_order_number) AS total_return_count
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(cr.total_return_count, 0) AS total_return_count,
        SUM(rs.total_sales) AS total_sales,
        AVG(rs.total_sales) AS avg_sales
    FROM
        customer c
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    LEFT JOIN
        RankedSales rs ON c.c_customer_sk = rs.web_site_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cr.total_return_amt, cr.total_return_count
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.total_return_amt,
    cs.total_return_count,
    RANK() OVER (ORDER BY cs.total_sales DESC) AS customer_sales_rank,
    CASE 
        WHEN cs.total_return_count > 0 THEN 'Returned'
        ELSE 'No Returns'
    END AS return_status,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status
FROM
    CustomerStats cs
WHERE
    cs.total_sales > 0
ORDER BY
    cs.total_sales DESC
LIMIT 100;
