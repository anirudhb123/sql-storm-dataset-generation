
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS total_return_ticket_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING total_spent IS NOT NULL
),
TopReturns AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        hvc.c_customer_id,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_spent
    FROM CustomerReturns cr
    JOIN HighValueCustomers hvc ON cr.sr_customer_sk = hvc.c_customer_id
    WHERE cr.total_returned_quantity > (
        SELECT AVG(total_returned_quantity) FROM CustomerReturns
    )
)
SELECT 
    tr.c_customer_id,
    tr.c_first_name,
    tr.c_last_name,
    tr.total_returned_quantity,
    tr.total_returned_amount,
    CASE 
        WHEN tr.total_returned_amount > 1000 THEN 'High Returner'
        WHEN tr.total_returned_amount BETWEEN 500 AND 1000 THEN 'Medium Returner'
        ELSE 'Low Returner'
    END AS return_category
FROM TopReturns tr
JOIN date_dim dd ON dd.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31')
WHERE dd.d_year = 2023
ORDER BY tr.total_returned_amount DESC, tr.total_returned_quantity DESC;
