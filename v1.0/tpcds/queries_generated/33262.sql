
WITH RECURSIVE SalesCTE AS (
    SELECT
        ss.sold_date_sk,
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM
        store_sales ss
    WHERE
        ss_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) -- filter for year 2022
    GROUP BY
        ss.sold_date_sk, ss_store_sk
),
TopStores AS (
    SELECT
        sc.ss_store_sk,
        sc.total_sales
    FROM
        SalesCTE sc
    WHERE
        sc.sales_rank <= 5
),
CustomerSpend AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_sk
    HAVING
        total_spent > (SELECT AVG(total_spent) FROM (
            SELECT
                SUM(ws.ws_net_paid) AS total_spent
            FROM
                web_sales ws
            GROUP BY
                ws.ws_bill_customer_sk) AS average_spent)
),
Returns AS (
    SELECT
        sr.returned_date_sk,
        SUM(sr.return_amt) AS total_returns
    FROM
        store_returns sr
    GROUP BY
        sr.returned_date_sk
)
SELECT
    da.d_date,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(r.total_returns, 0) AS total_returns,
    (COALESCE(ts.total_sales, 0) - COALESCE(r.total_returns, 0)) AS net_sales
FROM
    date_dim da
LEFT JOIN
    TopStores ts ON da.d_date_sk = ts.ss_store_sk
LEFT JOIN
    CustomerSpend cs ON cs.c_customer_sk = ts.ss_store_sk
LEFT JOIN
    Returns r ON da.d_date_sk = r.returned_date_sk
WHERE
    da.d_year = 2023 -- focusing on 2023
ORDER BY
    da.d_date;
