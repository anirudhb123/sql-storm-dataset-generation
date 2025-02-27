
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    WHERE 
        cr_returned_date_sk >= 20230101
    GROUP BY 
        cr_returning_customer_sk

    UNION ALL

    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk >= 20230101
    GROUP BY 
        wr_returning_customer_sk
),
AggregatedReturns AS (
    SELECT 
        customer_sk,
        SUM(total_return_quantity) AS total_quantity,
        SUM(total_return_amount) AS total_amount
    FROM (
        SELECT 
            cr_returning_customer_sk AS customer_sk,
            total_return_quantity,
            total_return_amount
        FROM 
            CustomerReturns

        UNION ALL

        SELECT 
            wr_returning_customer_sk AS customer_sk,
            total_return_quantity,
            total_return_amount
        FROM 
            CustomerReturns
    ) AS combined_returns
    GROUP BY 
        customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ar.total_quantity,
        ar.total_amount 
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        AggregatedReturns AS ar ON c.c_customer_sk = ar.customer_sk
)
SELECT 
    COALESCE(cd.c_first_name, 'Unknown') AS first_name,
    COALESCE(cd.c_last_name, 'Unknown') AS last_name,
    COUNT(ca.ca_address_sk) AS address_count,
    AVG(COALESCE(cd.total_amount, 0)) AS average_return_amount,
    COUNT(DISTINCT ca.ca_address_id) AS unique_addresses,
    SUM(CASE WHEN cd.total_quantity IS NULL THEN 0 ELSE cd.total_quantity END) AS total_returned_quantity
FROM 
    CustomerDetails AS cd
LEFT JOIN 
    customer_address AS ca ON cd.c_customer_sk = ca.ca_address_sk
GROUP BY 
    cd.c_customer_sk, cd.c_first_name, cd.c_last_name
HAVING 
    COUNT(ca.ca_address_sk) > 1 
ORDER BY 
    average_return_amount DESC
LIMIT 100;
