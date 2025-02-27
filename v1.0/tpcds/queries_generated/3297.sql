
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        RANK() OVER (ORDER BY cr.total_returned_amount DESC) AS rank
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    WHERE 
        cr.total_returned_quantity > 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_marital_status = 'M'
)
SELECT 
    tc.sr_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    td.cd_gender,
    td.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    tc.total_returned_quantity,
    tc.total_returned_amount
FROM 
    TopCustomers tc
LEFT JOIN 
    customer c ON tc.sr_customer_sk = c.c_customer_sk
LEFT JOIN 
    household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN 
    CustomerDemographics td ON c.c_current_cdemo_sk = td.cd_demo_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_returned_amount DESC;
