
WITH AddressDetails AS (
    SELECT ca_address_sk, 
           CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
           ca_city, 
           ca_state, 
           ca_zip
    FROM customer_address
), 
CustomerDetails AS (
    SELECT c_customer_id, 
           CONCAT(c_first_name, ' ', c_last_name) AS full_name, 
           cd_gender, 
           cd_marital_status, 
           cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
ReturnsSummary AS (
    SELECT sr_customer_sk, 
           SUM(sr_return_quantity) AS total_returns, 
           SUM(sr_return_amt) AS total_return_amt
    FROM store_returns 
    GROUP BY sr_customer_sk
) 
SELECT cd.full_name, 
       cd.cd_gender, 
       cd.cd_marital_status, 
       cd.cd_education_status, 
       ad.full_address, 
       ad.ca_city, 
       ad.ca_state, 
       ad.ca_zip, 
       COALESCE(rs.total_returns, 0) AS total_returns, 
       COALESCE(rs.total_return_amt, 0.00) AS total_return_amt
FROM CustomerDetails cd
JOIN AddressDetails ad ON cd.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_current_addr_sk = ad.ca_address_sk)
LEFT JOIN ReturnsSummary rs ON cd.c_customer_sk = rs.sr_customer_sk
ORDER BY cd.full_name, ad.ca_city;
