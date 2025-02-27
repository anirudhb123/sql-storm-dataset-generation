
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
        AND cd.cd_marital_status IN ('M', 'S')
),
high_value_customers AS (
    SELECT 
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_purchase_estimate
    FROM 
        ranked_customers rc
    WHERE 
        rc.rnk <= 10
),
item_sales AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
    HAVING 
        SUM(ws.ws_sales_price) IS NOT NULL
),
potential_promotion AS (
    SELECT 
        p.p_promo_id, 
        SUM(ws.ws_ext_discount_amt) AS total_discount, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        p.p_promo_id
),
customer_return_data AS (
    SELECT 
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    WHERE 
        sr.sr_return_quantity > 0
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.cd_gender,
    hi.total_sales,
    hi.order_count,
    pp.total_discount,
    pp.order_count AS promo_order_count,
    cr.total_return_amt,
    cr.return_count
FROM 
    high_value_customers hvc
LEFT JOIN 
    item_sales hi ON hi.total_sales > 1000
LEFT JOIN 
    potential_promotion pp ON pp.order_count > 5
LEFT JOIN 
    customer_return_data cr ON hvc.c_customer_id = cr.customer_sk
WHERE 
    hvc.cd_gender = 'F' AND 
    (cr.total_return_amt IS NULL OR cr.return_count <= 2)
ORDER BY 
    hvc.cd_purchase_estimate DESC, 
    hi.total_sales DESC;
