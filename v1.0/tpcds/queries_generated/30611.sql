
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
TopItems AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        s.total_sales, 
        s.order_count
    FROM 
        SalesCTE s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        s.sales_rank <= 10
), 
CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_id, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_zip
)
SELECT 
    t.i_item_id, 
    t.i_item_desc, 
    COALESCE(ca.customer_count, 0) AS customer_count,
    SUM(t.total_sales) AS total_sales_value
FROM 
    TopItems t
LEFT JOIN 
    CustomerAddressDetails ca ON ca.ca_zip IN (
        SELECT 
            DISTINCT ca.ca_zip 
        FROM 
            customer c 
        JOIN 
            customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
        WHERE 
            c.c_birth_year > 1980
    )
GROUP BY 
    t.i_item_id, t.i_item_desc, ca.customer_count
HAVING 
    SUM(t.total_sales) > 5000
ORDER BY 
    total_sales_value DESC;
