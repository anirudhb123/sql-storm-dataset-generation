
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
PromotionDetail AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_orders
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 5
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        coalesce(hd.hd_income_band_sk, -1) AS income_band,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) AS cust_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
)
SELECT 
    cs.c_customer_id,
    cs.income_band,
    ps.promo_orders,
    rs.total_sales
FROM 
    CustomerDetails cs
LEFT JOIN 
    PromotionDetail ps ON ps.promo_orders > 0
LEFT JOIN 
    RankedSales rs ON rs.web_site_sk = (SELECT MAX(web_site_sk) FROM web_site)
WHERE 
    cs.cust_rank = 1
ORDER BY 
    cs.income_band DESC, rs.total_sales DESC
LIMIT 10;
