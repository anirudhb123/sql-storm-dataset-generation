
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS total_return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
QualifiedReturns AS (
    SELECT 
        cr.ws_ship_customer_sk AS customer_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_quantity,
        COALESCE(c.total_return_amount, 0) AS total_return_amount,
        COALESCE(c.total_return_count, 0) AS total_return_count
    FROM 
        web_returns cr
    LEFT JOIN 
        CustomerReturns c ON cr.wr_returning_customer_sk = c.sr_customer_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    SUM(qr.cr_return_amount) AS total_returned_amount,
    SUM(qr.cr_return_tax) AS total_tax,
    AVG(qr.cr_return_quantity) AS avg_return_quantity
FROM 
    HighValueCustomers hvc
JOIN 
    QualifiedReturns qr ON hvc.c_customer_sk = qr.customer_sk
WHERE 
    hvc.rank <= 10
GROUP BY 
    hvc.c_customer_sk, hvc.c_first_name, hvc.c_last_name
HAVING 
    SUM(qr.cr_return_amount) > 1000
ORDER BY 
    total_returned_amount DESC;
