
WITH RankedPromotions AS (
    SELECT 
        p.p_promo_id, 
        p.p_promo_name,
        COUNT(CASE WHEN ws.ws_order_number IS NOT NULL THEN 1 END) AS total_sales,
        SUM(ws.ws_net_paid) AS total_net_paid,
        RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_item_sk = ws.ws_item_sk 
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
    WHERE 
        p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = '2023-10-01')
        AND p.p_end_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_date = '2023-01-01')
    GROUP BY 
        p.p_promo_id, p.p_promo_name
),
TopPromotions AS (
    SELECT 
        * 
    FROM 
        RankedPromotions 
    WHERE 
        sales_rank <= 10
)
SELECT 
    tp.p_promo_name,
    tp.total_sales,
    tp.total_net_paid,
    c.cd_gender,
    c.cd_marital_status,
    SUM(ws.ws_quantity) AS total_quantity_sold
FROM 
    TopPromotions tp
JOIN 
    web_sales ws ON tp.p_promo_id = ws.ws_order_number
JOIN 
    customer_demographics c ON ws.ws_bill_cdemo_sk = c.cd_demo_sk
GROUP BY 
    tp.p_promo_name, c.cd_gender, c.cd_marital_status
ORDER BY 
    tp.total_net_paid DESC;
