
WITH RECURSIVE total_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales_amount,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
item_with_promotion AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(p.p_promo_name, 'No Promotion') AS promo_name,
        ts.total_sales_amount,
        ts.order_count
    FROM 
        item i
    LEFT JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk
    LEFT JOIN 
        total_sales ts ON i.i_item_sk = ts.ws_item_sk
),
customer_analysis AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ROUND(AVG(cd.cd_purchase_estimate), 2) AS average_purchase
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, ca.ca_city
    HAVING 
        SUM(ws.ws_ext_sales_price) > 5000
),
final_output AS (
    SELECT 
        i.promo_name,
        it.i_item_desc,
        ts.total_sales_amount,
        tc.total_spent,
        ROUND(AVG(ca.average_purchase), 2) AS avg_customer_purchase
    FROM 
        item_with_promotion it
    LEFT JOIN 
        top_customers tc ON it.i_item_sk = tc.c_customer_sk
    LEFT JOIN 
        customer_analysis ca ON tc.c_customer_sk = ca.c_customer_sk
    WHERE 
        it.total_sales_amount IS NOT NULL
    GROUP BY 
        it.promo_name, it.i_item_desc, ts.total_sales_amount, tc.total_spent
)
SELECT 
    f.promo_name,
    f.i_item_desc,
    f.total_sales_amount,
    f.total_spent,
    f.avg_customer_purchase
FROM 
    final_output f
ORDER BY 
    f.total_sales_amount DESC, f.total_spent DESC
LIMIT 100;
