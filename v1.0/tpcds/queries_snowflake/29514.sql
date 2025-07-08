
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_spent_per_order,
        LISTAGG(DISTINCT CONCAT(p.p_promo_name, ': ', COALESCE(p.p_discount_active, 'N/A')), ', ') WITHIN GROUP (ORDER BY p.p_promo_name) AS promotions_used
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state
),
Ranking AS (
    SELECT 
        cs.*, 
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM 
        CustomerStats cs
)
SELECT 
    RANK() OVER (ORDER BY total_orders DESC) AS order_rank,
    customer_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    total_orders,
    total_spent,
    avg_spent_per_order,
    promotions_used,
    spending_rank
FROM 
    Ranking
WHERE 
    spending_rank <= 100
ORDER BY 
    spending_rank, order_rank;
