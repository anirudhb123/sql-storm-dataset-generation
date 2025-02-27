
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
Sales_Rank AS (
    SELECT 
        cs.c_customer_id AS customer_id,
        cs.total_net_profit,
        cs.total_orders,
        cs.average_order_value,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS sales_rank
    FROM 
        Customer_Sales cs
),
Top_Customers AS (
    SELECT 
        sr.customer_id,
        sr.total_net_profit,
        sr.total_orders,
        sr.average_order_value
    FROM 
        Sales_Rank sr
    WHERE 
        sr.sales_rank <= 10
),
Item_Sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_item_profit
    FROM 
        web_sales ws
    JOIN 
        Top_Customers tc ON ws.ws_bill_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = tc.customer_id)
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    its.total_quantity_sold,
    its.total_item_profit
FROM 
    item i
JOIN 
    Item_Sales its ON i.i_item_sk = its.ws_item_sk
ORDER BY 
    its.total_item_profit DESC
FETCH FIRST 10 ROWS ONLY;
