
WITH ranked_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_paid) AS total_spent,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
),
high_value_customers AS (
    SELECT 
        r.c_customer_sk, 
        r.c_first_name, 
        r.c_last_name
    FROM 
        ranked_sales r
    WHERE 
        r.purchase_rank = 1 AND r.total_spent > 1000
),
sales_details AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ship_mode_sk,
        sm.sm_type,
        hi.ib_lower_bound,
        hi.ib_upper_bound
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN 
        household_demographics hi ON ws.ws_bill_cdemo_sk = hi.hd_demo_sk
    WHERE 
        ws.ws_bill_customer_sk IN (SELECT c_customer_sk FROM high_value_customers)
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COUNT(sd.ws_order_number) AS order_count,
    SUM(sd.ws_quantity) AS total_items,
    SUM(sd.ws_ext_sales_price) AS total_sales,
    MAX(sd.ib_upper_bound) AS max_income_band
FROM 
    sales_details sd
JOIN 
    customer c ON sd.ws_bill_customer_sk = c.c_customer_sk
GROUP BY 
    c.c_first_name, 
    c.c_last_name
HAVING 
    SUM(sd.ws_ext_sales_price) > 5000
ORDER BY 
    total_sales DESC;
