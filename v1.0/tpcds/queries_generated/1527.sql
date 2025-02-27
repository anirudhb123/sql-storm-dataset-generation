
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
    JOIN
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
ReturnsData AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(sr.sr_ticket_number) AS total_returns
    FROM
        store_returns sr
    GROUP BY
        sr.sr_customer_sk
),
FinalReport AS (
    SELECT
        hvc.c_customer_id,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_sales,
        hvc.total_orders,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        COALESCE(rd.total_returns, 0) AS total_returns,
        hvc.total_sales - COALESCE(rd.total_return_amt, 0) AS net_sales
    FROM
        HighValueCustomers hvc
    LEFT JOIN
        ReturnsData rd ON hvc.c_customer_id = rd.sr_customer_sk
)
SELECT
    *,
    CASE
        WHEN net_sales > 10000 THEN 'High Value'
        WHEN net_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    FinalReport
WHERE
    sales_rank <= 100
ORDER BY
    net_sales DESC;
