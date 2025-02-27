
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), Max_Sales AS (
    SELECT 
        MAX(total_sales) AS max_sales 
    FROM 
        Sales_CTE
), Customer_Stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT CASE WHEN c.c_current_addr_sk IS NULL THEN NULL ELSE ws.order_number END) AS valid_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), Top_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_net_profit,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank
    FROM 
        Customer_Stats cs
    WHERE 
        cs.total_orders > 5
)
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT tc.c_customer_sk) AS active_customers,
    SUM(tc.total_net_profit) AS total_profit,
    MAX(tc.total_orders) AS max_orders
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    Top_Customers tc ON c.c_customer_sk = tc.c_customer_sk
LEFT JOIN 
    Max_Sales ms ON tc.total_net_profit >= ms.max_sales * 0.9
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT tc.c_customer_sk) > 10
ORDER BY 
    total_profit DESC, active_customers DESC;
