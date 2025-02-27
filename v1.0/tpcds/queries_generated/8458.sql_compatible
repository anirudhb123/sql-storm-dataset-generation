
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id, d.d_year
),
ranked_sales AS (
    SELECT 
        web_site_id,
        d_year,
        total_sales,
        total_orders,
        total_discount,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    web_site_id,
    d_year,
    total_sales,
    total_orders,
    total_discount,
    sales_rank
FROM 
    ranked_sales
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, sales_rank;
