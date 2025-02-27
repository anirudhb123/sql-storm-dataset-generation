
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
promotion_summary AS (
    SELECT 
        p.p_promo_sk,
        COUNT(ws_order_number) AS promo_order_count,
        SUM(ws_net_profit) AS total_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
)
SELECT 
    d.d_date AS sale_date,
    cs.order_count,
    cs.total_spent,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    ps.promo_order_count,
    ps.total_profit
FROM 
    date_dim d
LEFT JOIN 
    sales_summary ss ON d.d_date_sk = ss.ws_sold_date_sk
LEFT JOIN 
    customer_summary cs ON cs.c_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_first_shipto_date_sk = d.d_date_sk)
LEFT JOIN 
    promotion_summary ps ON ps.promo_order_count > 0
WHERE 
    d.d_current_month = '1' AND
    d.d_year = 2023
ORDER BY 
    d.d_date;
