
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        cd_gender,
        cd_marital_status,
        total_quantity,
        total_net_paid,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_net_paid DESC) AS rank_by_gender
    FROM 
        CustomerSales
)
SELECT 
    t.c_customer_id,
    t.cd_gender,
    t.cd_marital_status,
    t.total_quantity,
    t.total_net_paid,
    COALESCE(p.p_promo_name, 'No Promotion') AS promotion_name,
    COALESCE(wp.wp_url, 'No Website') AS website_url
FROM 
    TopCustomers t
LEFT JOIN 
    promotion p ON t.total_quantity > 100 AND t.rank_by_gender <= 10
LEFT JOIN 
    web_page wp ON t.c_customer_id = wp.wp_customer_sk
WHERE 
    t.rank_by_gender <= 10
ORDER BY 
    t.cd_gender, t.total_net_paid DESC;
