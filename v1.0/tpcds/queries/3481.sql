
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_ext_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS SalesRank,
        i.i_item_desc,
        i.i_current_price,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2452015 AND 2452045
),
TopSales AS (
    SELECT 
        rs.*, 
        SUM(rs.ws_ext_sales_price) OVER (PARTITION BY rs.c_customer_id) AS TotalCustomerSales
    FROM 
        RankedSales rs
    WHERE 
        rs.SalesRank <= 3 
)
SELECT 
    t.c_customer_id,
    CONCAT(t.c_first_name, ' ', t.c_last_name) AS CustomerName,
    COUNT(DISTINCT t.ws_order_number) AS TotalOrders,
    SUM(t.ws_ext_sales_price) AS TotalAmountSpent,
    AVG(t.ws_ext_sales_price) AS AverageOrderValue,
    STRING_AGG(DISTINCT CONCAT(t.i_item_desc, ' ($', ROUND(t.i_current_price, 2), ')'), ', ') AS TopItemsPurchased,
    COALESCE(t.ca_state, 'Unknown State') AS CustomerState
FROM 
    TopSales t
GROUP BY 
    t.c_customer_id, t.c_first_name, t.c_last_name, t.ca_state
HAVING 
    SUM(t.ws_ext_sales_price) > 1000
ORDER BY 
    TotalAmountSpent DESC
LIMIT 10;
