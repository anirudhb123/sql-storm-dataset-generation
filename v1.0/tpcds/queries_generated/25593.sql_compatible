
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY') AND 
        cd.cd_gender = 'F'
),
SalesSummary AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
),
FinalBenchmark AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        ss.total_quantity,
        ss.total_profit
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_id = ss.bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(total_profit, 0.00) AS total_profit,
    (CASE 
        WHEN COALESCE(total_quantity, 0) = 0 THEN 'No Sales'
        ELSE 'Sales Exists'
    END) AS sales_status
FROM 
    FinalBenchmark
ORDER BY 
    total_profit DESC, full_name;
