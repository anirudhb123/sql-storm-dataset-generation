
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
Top_Customers AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cs.total_spent,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        Customer_Sales cs
    JOIN 
        (SELECT 
            c_customer_sk, 
            c_first_name, 
            c_last_name 
         FROM 
            customer
         WHERE 
            c_current_cdemo_sk IS NOT NULL) c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.first_name,
    tc.last_name,
    COALESCE(tc.total_spent, 0) AS total_spent,
    COALESCE(tc.total_orders, 0) AS total_orders,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS customer_category
FROM 
    Top_Customers tc
WHERE 
    tc.rank IS NOT NULL
ORDER BY 
    total_spent DESC;

-- Additional Metrics
SELECT 
    d.d_year,
    SUM(ws.ws_net_paid) AS total_revenue,
    AVG(ws.ws_net_paid) AS average_order_value
FROM 
    web_sales ws
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    d.d_year
HAVING 
    SUM(ws.ws_net_paid) > 10000  -- Only consider years with significant revenue
ORDER BY 
    d.d_year DESC;

-- Cross Join Example with Filter
SELECT 
    c.c_first_name,
    c.c_last_name,
    i.i_item_desc,
    CASE WHEN o.net_sales IS NULL THEN 0 ELSE o.net_sales END AS net_sales
FROM 
    customer c
CROSS JOIN 
    item i
LEFT JOIN (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_paid) AS net_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    ) o ON i.i_item_sk = o.ws_item_sk
WHERE 
    c.c_current_addr_sk IS NOT NULL AND
    (i.i_current_price IS NULL OR i.i_current_price < 50)
ORDER BY 
    c.c_last_name, net_sales DESC;
