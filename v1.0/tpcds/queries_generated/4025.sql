
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count,
        cs.last_purchase_date,
        ROW_NUMBER() OVER (PARTITION BY DATE_TRUNC('year', last_purchase_date) ORDER BY total_spent DESC) AS rank
    FROM
        CustomerSales cs
    WHERE
        cs.total_spent > (
            SELECT AVG(total_spent) FROM CustomerSales
        )
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(sr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_catalog_returns, 0) AS total_catalog_returns,
    hvc.total_spent
FROM 
    HighValueCustomers hvc
LEFT JOIN (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
) sr ON hvc.c_customer_sk = sr.sr_returning_customer_sk
LEFT JOIN (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_catalog_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
) cr ON hvc.c_customer_sk = cr.cr_returning_customer_sk
WHERE 
    hvc.rank <= 10
ORDER BY 
    hvc.total_spent DESC;
