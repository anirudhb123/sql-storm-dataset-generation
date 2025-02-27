
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE 
        c.c_customer_sk <> ch.c_customer_sk
),
DateSales AS (
    SELECT 
        d.d_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date_sk
),
TopProducts AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        item i 
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_product_name
    ORDER BY 
        total_quantity DESC
    LIMIT 10
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    da.total_sales,
    tp.i_product_name,
    tp.total_quantity,
    COALESCE(tp.total_quantity, 0) AS purchased_quantity
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    DateSales da ON da.d_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
LEFT JOIN 
    TopProducts tp ON tp.i_item_id = (SELECT i.i_item_id FROM item i WHERE i.i_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = ch.c_customer_sk LIMIT 1))
WHERE 
    ch.level = 0
ORDER BY 
    ch.c_last_name, ch.c_first_name;
