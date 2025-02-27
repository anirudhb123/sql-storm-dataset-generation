
WITH AddressCounts AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_sk) AS address_count 
    FROM 
        customer_address 
    WHERE 
        ca_city LIKE '%ville%' 
    GROUP BY 
        ca_state
), 
CustomerDemographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate 
    FROM 
        customer_demographics 
    GROUP BY 
        cd_gender, 
        cd_marital_status
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales 
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
), 
CombinedData AS (
    SELECT 
        a.ca_state, 
        d.cd_gender, 
        d.cd_marital_status, 
        c.total_sales, 
        a.address_count, 
        d.avg_purchase_estimate 
    FROM 
        AddressCounts a 
    JOIN 
        CustomerDemographics d ON d.cd_demo_sk IN (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_state = a.ca_state)) 
    LEFT JOIN 
        SalesData c ON c.ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_state = a.ca_state))
)
SELECT 
    ca_state, 
    cd_gender, 
    cd_marital_status, 
    SUM(total_sales) AS total_sales, 
    SUM(address_count) AS total_address_count, 
    AVG(avg_purchase_estimate) AS overall_avg_purchase_estimate 
FROM 
    CombinedData 
GROUP BY 
    ca_state, 
    cd_gender, 
    cd_marital_status 
ORDER BY 
    total_sales DESC, 
    ca_state;
