
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk, 
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        RANK() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
    HAVING 
        total_returns > 1
), 
TopCustomers AS (
    SELECT 
        cr_returning_customer_sk, 
        total_returns, 
        total_return_amount
    FROM 
        RankedReturns
    WHERE 
        return_rank <= 10
), 
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        a.ca_country,
        a.ca_state,
        a.ca_city,
        CASE 
            WHEN a.ca_city IS NULL THEN 'Unknown' 
            ELSE a.ca_city 
        END AS display_city
    FROM 
        customer c 
    LEFT JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    ca.display_city, 
    COUNT(DISTINCT ct.cr_returning_customer_sk) AS returning_customers,
    SUM(ct.total_return_amount) AS total_returned_value,
    AVG(ct.total_returns) AS avg_returns_per_customer,
    CASE 
        WHEN COUNT(DISTINCT ca.c_customer_sk) = 0 
        THEN 'No returns available' 
        ELSE 'Data available' 
    END AS return_data_status
FROM 
    CustomerAddresses ca
JOIN 
    TopCustomers ct ON ca.c_customer_sk = ct.cr_returning_customer_sk
GROUP BY 
    ca.display_city
ORDER BY 
    total_returned_value DESC
FETCH FIRST 5 ROWS ONLY;
