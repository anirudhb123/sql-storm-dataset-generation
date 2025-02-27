
WITH RECURSIVE previous_sales AS (
    SELECT 
        ws.web_site_sk, 
        ws_sold_date_sk, 
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk < (SELECT MAX(ws2.ws_sold_date_sk) FROM web_sales ws2) -- Filter for previous sales
    GROUP BY 
        ws.web_site_sk, 
        ws_sold_date_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_quantity) AS total_purchases,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        RANK() OVER (ORDER BY cs.total_purchases DESC) AS purchase_rank
    FROM 
        customer_stats cs
    WHERE 
        cs.total_purchases > 0
)

SELECT 
    cac.ca_city,
    cac.ca_state,
    tc.c_first_name,
    tc.c_last_name,
    tc.purchase_rank,
    ps.total_sales,
    (ps.total_sales - COALESCE(SUM(ws.ws_net_paid), 0)) AS potential_loss
FROM 
    previous_sales ps
JOIN 
    store s ON ps.web_site_sk = s.s_store_sk
JOIN 
    top_customers tc ON tc.c_customer_sk = s.s_store_sk
JOIN 
    customer_address cac ON cac.ca_address_sk = s.s_store_sk
GROUP BY 
    cac.ca_city, 
    cac.ca_state, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.purchase_rank,
    ps.total_sales
HAVING 
    potential_loss > 1000.00 
ORDER BY 
    cac.ca_city, 
    cac.ca_state;
