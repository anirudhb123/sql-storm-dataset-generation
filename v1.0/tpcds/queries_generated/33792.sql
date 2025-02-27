
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        ws_sold_date_sk, 
        SUM(ws_quantity) AS total_quantity, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
), 
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.net_profit) AS total_profit,
        COUNT(DISTINCT ws.order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_profit > (SELECT AVG(total_profit) FROM CustomerSales) 
)
SELECT 
    ca.ca_city,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    COALESCE(COUNT(DISTINCT cs.order_count), 0) AS top_customer_orders,
    CASE 
        WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'High Sales'
        ELSE 'Regular Sales'
    END AS sales_category
FROM 
    web_sales ws
LEFT JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    TopCustomers tc ON c.c_customer_id = tc.customer_id
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY 
    ca.ca_city
HAVING 
    total_sales > 5000
ORDER BY 
    total_sales DESC;
