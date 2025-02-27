
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cr.return_count,
        cr.total_return_amt,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cr.total_return_amt DESC) AS city_rank
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cr.total_return_amt > (SELECT AVG(total_return_amt) FROM CustomerReturns)
),
TopReturningCustomers AS (
    SELECT 
        hrc.sr_customer_sk,
        hrc.return_count,
        hrc.total_return_amt,
        hrc.c_first_name,
        hrc.c_last_name,
        hrc.cd_gender,
        hrc.cd_marital_status,
        hrc.cd_credit_rating,
        hrc.ca_city
    FROM 
        HighReturnCustomers hrc
    WHERE 
        hrc.city_rank <= 5
)
SELECT 
    T.sr_customer_sk,
    T.c_first_name,
    T.c_last_name,
    T.return_count,
    T.total_return_amt,
    T.cd_gender,
    T.cd_marital_status,
    CASE 
        WHEN T.cd_credit_rating IS NULL THEN 'Unknown'
        ELSE T.cd_credit_rating
    END AS credit_rating,
    COALESCE(SM.sm_type, 'Standard') AS shipment_type
FROM 
    TopReturningCustomers T
LEFT JOIN 
    ship_mode SM ON T.return_count > 10 AND SM.sm_ship_mode_sk = (SELECT sm_ship_mode_sk FROM ship_mode ORDER BY RANDOM() LIMIT 1)
ORDER BY 
    T.total_return_amt DESC
LIMIT 25;
