
WITH CustomerReturns AS (
    SELECT
        r.cr_returning_customer_sk AS customer_sk,
        SUM(r.cr_return_quantity) AS total_returned_qty,
        SUM(r.cr_return_amt) AS total_returned_amt,
        COUNT(DISTINCT r.cr_order_number) AS return_count
    FROM
        catalog_returns r
    GROUP BY
        r.cr_returning_customer_sk
),
CustomerSales AS (
    SELECT
        w.ws_ship_customer_sk AS customer_sk,
        SUM(w.ws_quantity) AS total_sold_qty,
        SUM(w.ws_net_paid) AS total_sold_amt
    FROM
        web_sales w
    GROUP BY
        w.ws_ship_customer_sk
),
CustomerSegment AS (
    SELECT
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COALESCE(cr.total_returned_qty, 0) AS total_returned_qty,
        COALESCE(cs.total_sold_qty, 0) AS total_sold_qty,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
        COALESCE(cs.total_sold_amt, 0) AS total_sold_amt,
        (COALESCE(cs.total_sold_amt, 0) - COALESCE(cr.total_returned_amt, 0)) AS net_sales
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.customer_sk
    LEFT JOIN CustomerSales cs ON c.c_customer_sk = cs.customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.gender,
    cs.total_returned_qty,
    cs.total_sold_qty,
    cs.total_returned_amt,
    cs.total_sold_amt,
    cs.net_sales,
    CASE
        WHEN cs.net_sales < 0 THEN 'Loss'
        WHEN cs.net_sales >= 0 AND cs.net_sales < 1000 THEN 'Low'
        WHEN cs.net_sales >= 1000 AND cs.net_sales < 5000 THEN 'Medium'
        ELSE 'High'
    END AS sales_category
FROM
    CustomerSegment cs
WHERE
    cs.total_sold_qty > 0
ORDER BY
    cs.net_sales DESC
LIMIT 10;
