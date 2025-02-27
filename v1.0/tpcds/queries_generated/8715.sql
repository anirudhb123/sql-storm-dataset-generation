
WITH Customer_Returns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        customer c
    JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
High_Value_Customers AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        cr.total_return_quantity,
        cd.cd_credit_rating,
        cd.cd_income_band_sk
    FROM 
        Customer_Returns cr
    JOIN 
        customer_demographics cd ON cr.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cr.total_return_amount > 500
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_returns,
    hvc.total_return_amount,
    hvc.total_return_quantity,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    High_Value_Customers hvc
JOIN 
    income_band ib ON hvc.cd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    hvc.total_return_amount DESC
LIMIT 10;
