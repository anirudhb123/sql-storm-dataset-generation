
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_country = 'USA' 
        AND ws.ws_sold_date_sk BETWEEN 2459811 AND 2459993 -- dates for a specific month
    GROUP BY 
        c.c_customer_id
), 
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_profit,
        order_count,
        RANK() OVER (ORDER BY total_profit DESC) AS rank_profit
    FROM 
        CustomerSales
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        TopCustomers tc ON ws.ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_customer_id = tc.c_customer_id)
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(is.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(is.total_profit, 0) AS total_profit
FROM 
    item i
LEFT JOIN 
    ItemSales is ON i.i_item_sk = is.ws_item_sk
WHERE 
    i.i_current_price > 50.00 -- items with a price greater than $50
ORDER BY 
    total_profit DESC
LIMIT 10;
