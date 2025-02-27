
WITH CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
ActiveCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name, 
        c_last_name,
        cd_gender,
        cd_marital_status,
        COALESCE(AVG(cd_purchase_estimate), 0) AS average_purchase_estimate
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name, cd_gender, cd_marital_status
)
SELECT 
    ac.c_customer_sk,
    ac.c_first_name,
    ac.c_last_name,
    ac.cd_gender,
    ac.cd_marital_status,
    cr.total_returned_quantity,
    cr.total_returned_amt,
    ROW_NUMBER() OVER (PARTITION BY ac.cd_gender ORDER BY cr.total_returned_amt DESC) AS rank_by_return_amt,
    COUNT(cr.total_returned_quantity) OVER (PARTITION BY ac.cd_gender) AS total_returning_customers,
    CASE 
        WHEN ac.average_purchase_estimate > 1000 THEN 'High Value'
        WHEN ac.average_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    ActiveCustomers ac
LEFT JOIN 
    CustomerReturns cr ON ac.c_customer_sk = cr.sr_returning_customer_sk
WHERE 
    cr.total_returned_quantity IS NOT NULL
    AND (ac.cd_gender = 'F' OR ac.cd_gender = 'M')
ORDER BY 
    ac.cd_gender, cr.total_returned_amt DESC;
