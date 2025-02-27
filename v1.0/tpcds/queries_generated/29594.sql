
SELECT 
    ca_city AS City,
    COUNT(DISTINCT c_customer_id) AS Unique_Customers,
    AVG(cd_purchase_estimate) AS Avg_Purchase_Estimate,
    STRING_AGG(DISTINCT cd_gender, ', ') AS Genders,
    STRING_AGG(DISTINCT cd_marital_status, ', ') AS Marital_Statuses,
    SUM(ss_quantity) AS Total_Quantity_Sold,
    SUM(ss_net_profit) AS Total_Net_Profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2022 AND
    ca.ca_state = 'NY'
GROUP BY 
    ca_city
ORDER BY 
    Total_Net_Profit DESC
LIMIT 10;
