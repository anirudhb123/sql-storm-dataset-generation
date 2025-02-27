
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_customer_sk) AS unique_customers,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id, ws.ws_order_number
), promotional_data AS (
    SELECT 
        p.p_promo_id,
        COUNT(p.p_promo_sk) AS promo_count,
        SUM(p.p_cost) AS total_promo_spent
    FROM 
        promotion p
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_id
)

SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.unique_customers,
    sd.total_quantity,
    pd.promo_count,
    pd.total_promo_spent,
    COALESCE(CASE 
        WHEN sd.sales_rank = 1 THEN 'Best Seller' 
        ELSE 'Regular' 
    END, 'No Sales') AS sales_category
FROM 
    sales_data sd
LEFT JOIN 
    promotional_data pd ON sd.web_site_id = pd.p_promo_id
WHERE 
    sd.total_sales > 1000
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
