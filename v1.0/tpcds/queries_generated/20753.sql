
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS unique_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_returned_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
Demographics AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        d.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(wr.unique_web_returns, 0) AS unique_web_returns
    FROM 
        Demographics d
    LEFT JOIN 
        CustomerReturns cr ON d.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebReturns wr ON d.c_customer_sk = wr.wr_returning_customer_sk
    WHERE 
        (d.cd_gender = 'F' AND d.cd_marital_status = 'M' AND d.cd_education_status = 'PhD') 
        OR 
        (d.cd_gender = 'M' AND d.cd_marital_status = 'S' AND total_returned_quantity > 5)
),
RankedReturns AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.cd_gender,
        RANK() OVER (PARTITION BY hvc.cd_marital_status ORDER BY hvc.total_returned_quantity DESC) AS return_rank,
        hvc.unique_web_returns
    FROM 
        HighValueCustomers hvc
)
SELECT 
    d.d_date,
    COUNT(DISTINCT rr.c_customer_sk) AS total_customers,
    AVG(rr.unique_web_returns) AS average_unique_web_returns
FROM 
    date_dim d
LEFT JOIN 
    RankedReturns rr ON rr.c_customer_sk IN (
        SELECT c_customer_sk 
        FROM customer 
        WHERE c_first_shipto_date_sk = d.d_date_sk
    )
WHERE 
    d.d_year = 2023
GROUP BY 
    d.d_date
ORDER BY 
    d.d_date;
