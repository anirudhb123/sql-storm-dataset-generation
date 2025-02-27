
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(sd.total_profit) AS city_profit,
    COUNT(DISTINCT sd.customer_sk) AS unique_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(sd.order_count) AS max_orders,
    STRING_AGG(CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Unknown' 
    END, ', ') AS gender_distribution
FROM 
    SalesData sd
JOIN 
    CustomerDemographics cd ON sd.customer_sk = cd.c_customer_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = (
        SELECT c.c_current_addr_sk 
        FROM customer c 
        WHERE c.c_customer_sk = sd.customer_sk
    )
WHERE 
    sd.rnk <= 10 
    AND cd.purchase_rank <= 5 
    AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(sd.total_profit) > 10000
ORDER BY 
    city_profit DESC
LIMIT 15;
