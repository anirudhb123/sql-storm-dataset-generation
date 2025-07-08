
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_purchase_estimate
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        cd.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
        JOIN CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.c_customer_sk
),
GenderProfitSummary AS (
    SELECT 
        cd.cd_gender,
        SUM(ss.total_net_profit) AS gender_net_profit,
        SUM(ss.total_orders) AS gender_order_count
    FROM 
        SalesSummary ss
        JOIN CustomerDetails cd ON ss.c_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    g.cd_gender,
    g.gender_net_profit,
    g.gender_order_count,
    LISTAGG(CONCAT('Customer ID: ', c.c_customer_sk, ', Full Name: ', c.full_name), '; ') AS customer_details
FROM 
    GenderProfitSummary g
    JOIN CustomerDetails c ON g.cd_gender = c.cd_gender
GROUP BY 
    g.cd_gender, g.gender_net_profit, g.gender_order_count
ORDER BY 
    g.gender_net_profit DESC;
