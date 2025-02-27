
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT
        cs.c_customer_id,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
    WHERE
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
SalesSummary AS (
    SELECT
        hvc.c_customer_id,
        hvc.total_sales,
        CASE 
            WHEN hvc.sales_rank <= 10 THEN 'Top 10%'
            ELSE 'Above Average'
        END AS customer_segment
    FROM
        HighValueCustomers hvc
)
SELECT
    hvc.c_customer_id,
    hvc.total_sales,
    hvc.customer_segment,
    COALESCE(sr.return_quantity, 0) AS total_returns,
    COALESCE(sr.total_return_value, 0) AS total_return_value,
    hvc.total_sales - COALESCE(sr.total_return_value, 0) AS net_sales
FROM
    SalesSummary hvc
LEFT JOIN (
    SELECT
        sr_customer_sk,
        COUNT(sr_ticket_number) AS return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
) sr ON hvc.c_customer_id = sr.sr_customer_sk
WHERE
    hvc.total_sales > 1000
ORDER BY
    hvc.total_sales DESC;
