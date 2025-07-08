
WITH RecentReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_quantity) AS total_returned_quantity, 
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns)
    GROUP BY 
        sr_customer_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) as row_num
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), 
MaxReturnedCustomer AS (
    SELECT 
        r.sr_customer_sk, 
        r.total_returned_quantity, 
        r.total_returned_amt 
    FROM 
        RecentReturns r
    ORDER BY 
        r.total_returned_quantity DESC 
    LIMIT 1
), 
AddressDetails AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state, 
        COUNT(DISTINCT wr.wr_item_sk) AS total_web_returns
    FROM 
        customer_address ca
    JOIN 
        web_returns wr ON ca.ca_address_sk = wr.wr_returning_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    cd.c_first_name, 
    cd.c_last_name, 
    cd.cd_gender,
    COALESCE(ad.total_web_returns, 0) AS total_web_returns,
    rc.total_returned_quantity, 
    rc.total_returned_amt
FROM 
    CustomerDetails cd
JOIN 
    MaxReturnedCustomer rc ON cd.c_customer_sk = rc.sr_customer_sk
LEFT JOIN 
    AddressDetails ad ON cd.c_customer_sk = (SELECT MAX(c.c_customer_sk) 
                                             FROM customer c 
                                             WHERE c.c_current_addr_sk = ad.ca_address_sk)
WHERE 
    (cd.cd_gender = 'F' AND rc.total_returned_quantity > 10)
    OR (cd.cd_gender = 'M' AND rc.total_returned_quantity <= 5)
ORDER BY 
    rc.total_returned_quantity DESC, 
    cd.c_last_name ASC
FETCH FIRST 10 ROWS ONLY;
