
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_net_profit) > 1000
),
Customer_Segmentation AS (
    SELECT 
        c.c_customer_id,
        CASE 
            WHEN cd_marital_status = 'M' AND cd_purchase_estimate > 5000 THEN 'High Value'
            WHEN cd_marital_status = 'S' AND cd_purchase_estimate <= 5000 THEN 'Budget Conscious'
            ELSE 'Other'
        END AS segment
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Top_Customers AS (
    SELECT 
        s.ws_bill_customer_sk,
        cs.segment,
        s.total_profit,
        s.total_orders
    FROM Sales_CTE s
    JOIN Customer_Segmentation cs ON s.ws_bill_customer_sk = cs.c_customer_id
    WHERE s.rank <= 10
)
SELECT 
    a.ca_city,
    SUM(tc.total_profit) AS city_profit,
    COUNT(DISTINCT tc.ws_bill_customer_sk) AS unique_customers,
    AVG(tc.total_orders) AS avg_orders
FROM Top_Customers tc
JOIN customer_address a ON a.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_id = tc.ws_bill_customer_sk)
GROUP BY a.ca_city
ORDER BY city_profit DESC
LIMIT 5;
