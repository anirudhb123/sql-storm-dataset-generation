
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS Total_Profit,
        COUNT(ws_order_number) AS Order_Count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS Profit_Rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.net_paid) AS Total_Spending,
        COUNT(ws.ws_order_number) AS Order_Count,
        MAX(ws.ws_sold_date_sk) AS Last_Order_Date
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
FilteredProducts AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(wc.ws_net_profit), 0) AS Total_Profit
    FROM 
        item i 
    LEFT JOIN 
        web_sales wc ON i.i_item_sk = wc.ws_item_sk AND wc.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        i.i_item_sk, i.i_item_id
)
SELECT 
    ca.ca_city,
    SUM(ps.Total_Profit) AS Total_City_Profit,
    COUNT(DISTINCT cs.c_customer_sk) AS Unique_Customers,
    ROUND(AVG(cs.Total_Spending), 2) AS Avg_Spending_Per_Customer
FROM 
    customer_address ca 
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
JOIN 
    FilteredProducts ps ON ps.i_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_order_number IN (SELECT sr_ticket_number FROM store_returns sr WHERE sr_return_quantity > 1))
WHERE 
    ca.ca_state = 'CA'
    AND cs.Order_Count > 5
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ps.Total_Profit) > (SELECT AVG(Total_Profit) FROM SalesCTE WHERE Profit_Rank = 1)
ORDER BY 
    Total_City_Profit DESC;
