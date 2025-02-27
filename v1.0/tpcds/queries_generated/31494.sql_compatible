
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws.sold_date_sk,
        ws.item_sk,
        SUM(ws.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.sold_date_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.sold_date_sk, ws.item_sk
    HAVING 
        SUM(ws.net_profit) > 0
), 
Customer_Sales AS (
    SELECT 
        c.customer_sk,
        SUM(ws.net_profit) AS total_spent,
        COUNT(ws.order_number) AS total_orders
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_country IS NOT NULL
    GROUP BY 
        c.customer_sk
), 
Aggregate_Demo AS (
    SELECT 
        cd_demo_sk,
        AVG(cd_purchase_estimate) AS average_purchase,
        MAX(cd_dep_count) AS max_dep,
        MIN(cd_dep_college_count) AS min_college_deps
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk
)

SELECT 
    ca.city,
    ca.state,
    SUM(COALESCE(cs.total_spent, 0)) AS total_customer_spent,
    AVG(COALESCE(ad.average_purchase, 0)) AS avg_demographics_purchase,
    COUNT(DISTINCT cs.customer_sk) AS number_of_customers,
    COUNT(DISTINCT ss.ticket_number) AS total_sales,
    RANK() OVER (ORDER BY SUM(COALESCE(cs.total_spent, 0)) DESC) AS sales_rank
FROM 
    customer_address ca
LEFT JOIN 
    Customer_Sales cs ON ca.ca_address_sk = cs.customer_sk
LEFT JOIN 
    Aggregate_Demo ad ON cs.customer_sk = ad.cd_demo_sk
LEFT JOIN 
    store_sales ss ON cs.customer_sk = ss.ss_customer_sk
WHERE 
    ca.state IN ('NY', 'CA')
GROUP BY 
    ca.city, ca.state
HAVING 
    SUM(COALESCE(cs.total_spent, 0)) > 100000
ORDER BY 
    sales_rank;
