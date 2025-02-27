
WITH ConcatenatedNames AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CityCounts AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
),
DateStatistics AS (
    SELECT 
        d.d_year,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
Top10Promos AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_sales_price) AS total_revenue
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
    ORDER BY 
        total_revenue DESC
    LIMIT 10
)
SELECT 
    cn.full_name,
    cn.c_email_address,
    cn.cd_gender,
    cn.cd_marital_status,
    cc.ca_city,
    cc.customer_count,
    ds.d_year,
    ds.total_orders,
    ds.total_sales,
    tp.p_promo_name,
    tp.total_revenue
FROM 
    ConcatenatedNames cn
CROSS JOIN 
    CityCounts cc
CROSS JOIN 
    DateStatistics ds
CROSS JOIN 
    Top10Promos tp
WHERE 
    cn.cd_gender = 'F'
    AND ds.total_orders > 1000
    AND cc.customer_count > 20
ORDER BY 
    tp.total_revenue DESC, 
    cn.full_name;
