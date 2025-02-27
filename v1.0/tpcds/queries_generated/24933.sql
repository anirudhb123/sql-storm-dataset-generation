
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amount,
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        ROW_NUMBER() OVER (ORDER BY cr.total_returned_amount DESC) AS rn
    FROM 
        CustomerReturns cr
    WHERE 
        cr.total_returned_amount > (SELECT AVG(total_returned_amount) FROM CustomerReturns)
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
CustomerDetails AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cr.total_returns,
        cr.total_returned_amount,
        cr.total_returned_quantity
    FROM 
        TopCustomers tc
    JOIN 
        CustomerReturns cr ON tc.sr_customer_sk = cr.sr_customer_sk
    JOIN 
        CustomerDemographics cd ON tc.sr_customer_sk = cd.c_customer_sk
    JOIN 
        customer c ON tc.sr_customer_sk = c.c_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
    COALESCE(cd.cd_education_status, 'Not Specified') AS education_status,
    cd.total_returns,
    cd.total_returned_amount,
    cd.total_returned_quantity,
    CASE 
        WHEN cd.total_returns > 10 THEN 'Frequent Returner'
        WHEN cd.total_returns BETWEEN 5 AND 10 THEN 'Moderate Returner'
        ELSE 'Occasional Returner'
    END AS return_category,
    (SELECT 
        COUNT(*) 
     FROM 
        store s 
     WHERE 
        s.s_number_employees IS NOT NULL) AS total_stores,
    STRING_AGG(DISTINCT s.s_store_name, ', ' ORDER BY s.s_store_name) AS associated_stores
FROM 
    CustomerDetails cd
LEFT JOIN 
    store s ON cd.s_store_sk = s.s_store_sk
WHERE 
    cd.total_returned_quantity > (
        SELECT 
            AVG(total_returned_quantity) 
        FROM 
            CustomerReturns
        WHERE 
            total_returned_quantity IS NOT NULL
    )
GROUP BY 
    cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.total_returns, cd.total_returned_amount, cd.total_returned_quantity
HAVING 
    COUNT(s.s_store_sk) > 0
ORDER BY 
    cd.total_returned_amount DESC
LIMIT 100;
