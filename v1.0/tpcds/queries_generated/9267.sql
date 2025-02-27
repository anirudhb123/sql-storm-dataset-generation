
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
TopSales AS (
    SELECT 
        r.ws_item_sk,
        i.i_item_desc, 
        i.i_current_price,
        r.total_quantity_sold,
        r.total_net_paid
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 5
),
SalesByCustomer AS (
    SELECT 
        c.c_customer_id, 
        SUM(ts.total_net_paid) AS total_spent
    FROM 
        TopSales ts
    JOIN 
        web_sales ws ON ts.ws_item_sk = ws.ws_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.total_spent,
    COALESCE(d.d_country, 'Unknown') AS country
FROM 
    SalesByCustomer s
JOIN 
    customer c ON s.c_customer_id = c.c_customer_id
LEFT JOIN 
    customer_address d ON c.c_current_addr_sk = d.ca_address_sk
WHERE 
    s.total_spent > 1000
ORDER BY 
    total_spent DESC;
