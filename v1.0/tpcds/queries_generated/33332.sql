
WITH RECURSIVE Sales_Hierarchy AS (
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_net_profit) AS total_profit,
        1 AS level
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
    UNION ALL
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        level + 1
    FROM 
        web_sales
    INNER JOIN Sales_Hierarchy ON ws_bill_customer_sk = Sales_Hierarchy.customer_sk
    GROUP BY 
        ws_bill_customer_sk
),
Customer_Demo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate >= 1000
),
Top_Customers AS (
    SELECT 
        sh.customer_sk,
        sh.total_profit,
        ROW_NUMBER() OVER (PARTITION BY sh.level ORDER BY sh.total_profit DESC) AS rank
    FROM 
        Sales_Hierarchy sh
    WHERE 
        sh.total_profit > 5000
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        Customer_Demo cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(COALESCE(sh.total_profit, 0)) AS total_sales_profit
FROM 
    Customer_Info ci
INNER JOIN 
    Top_Customers tc ON ci.c_customer_sk = tc.customer_sk
LEFT JOIN 
    Sales_Hierarchy sh ON ci.c_customer_sk = sh.customer_sk
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.ca_city, 
    ci.cd_gender, 
    ci.cd_marital_status
HAVING 
    SUM(COALESCE(sh.total_profit, 0)) > 5000
ORDER BY 
    total_sales_profit DESC;
