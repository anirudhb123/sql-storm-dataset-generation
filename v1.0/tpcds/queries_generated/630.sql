
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_sales_price DESC) AS rank_by_sales
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
), CustomerReturns AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amount,
        AVG(wr.wr_return_quantity) AS avg_returned_quantity
    FROM
        web_returns wr
    JOIN
        customer c ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY
        c.c_customer_id
), TotalSales AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
), Summary AS (
    SELECT
        c.c_customer_id,
        COALESCE(ts.total_sales, 0) AS total_sales,
        COALESCE(cr.total_web_returns, 0) AS total_web_returns,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(cr.avg_returned_quantity, 0) AS avg_returned_quantity,
        CASE
            WHEN COALESCE(ts.total_sales, 0) > 1000 THEN 'High-Value'
            WHEN COALESCE(ts.total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium-Value'
            ELSE 'Low-Value'
        END AS customer_value_category
    FROM
        customer c
    LEFT JOIN
        TotalSales ts ON ts.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN
        CustomerReturns cr ON cr.c_customer_id = c.c_customer_id
)
SELECT
    s.web_site_id,
    s.rank_by_sales,
    COALESCE(s.total_sales, 0) AS total_sales,
    si.customer_value_category
FROM
    RankedSales s
JOIN
    Summary si ON s.web_site_id = si.c_customer_id
WHERE
    s.rank_by_sales <= 10
ORDER BY
    s.web_site_id, total_sales DESC;
