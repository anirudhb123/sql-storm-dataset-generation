
WITH RECURSIVE MonthlySales AS (
    SELECT
        d.d_month_seq,
        SUM(ss_ext_sales_price) AS total_sales
    FROM
        date_dim d
    LEFT JOIN
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        d.d_month_seq
    
    UNION ALL

    SELECT
        d.d_month_seq,
        SUM(ss_ext_sales_price) AS total_sales
    FROM
        date_dim d
    INNER JOIN
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE
        d.d_year = 2023 AND d.d_month_seq > (SELECT MIN(m.d_month_seq) FROM MonthlySales m)
    GROUP BY
        d.d_month_seq
),
CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_returned_amt
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
        CASE 
            WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' 
            ELSE 'Not Profitable' 
        END AS profitability_status
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, cr.total_returned_amt
)
SELECT
    ms.d_month_seq,
    SUM(ms.total_sales) AS month_sales,
    SUM(cs.total_returned_amt) AS month_returns,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers
FROM
    MonthlySales ms
JOIN 
    CustomerStats cs ON ms.d_month_seq = (SELECT d_month_seq FROM date_dim WHERE d_year = 2023)
GROUP BY 
    ms.d_month_seq
ORDER BY 
    ms.d_month_seq;
