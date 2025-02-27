
WITH RECURSIVE income_bracket AS (
    SELECT 
        CASE 
            WHEN ib_lower_bound IS NULL THEN 'Unknown'
            WHEN ib_upper_bound IS NULL THEN 'Infinite'
            ELSE CONCAT('$', ib_lower_bound, ' - $', COALESCE(ib_upper_bound, 'MAX')) 
        END AS income_category,
        ib_income_band_sk 
    FROM 
        income_band
), 
sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales 
    WHERE 
        ws_quantity > 0
    AND 
        ws_net_paid IS NOT NULL
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'N/A') AS gender,
        COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
        COUNT(DISTINCT s.s_store_sk) AS store_count,
        COALESCE(SUM(si.s_quantity), 0) AS total_sales_qty,
        SUM(CASE WHEN s.s_zip IS NULL THEN 0 ELSE 1 END) AS valid_zip_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store s ON s.s_store_sk IN (
            SELECT sr_store_sk FROM store_returns 
            WHERE sr_customer_sk = c.c_customer_sk
        )
    LEFT JOIN 
        sales_data si ON c.c_customer_sk = si.ws_item_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
promotion_summary AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT p.p_promo_sk) AS promo_count,
        SUM(COALESCE(ws_ext_sales_price, 0)) AS total_sales_with_discount
    FROM 
        promotion p 
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    ci.gender,
    ci.marital_status,
    ci.store_count,
    ib.income_category,
    ps.promo_count,
    ps.total_sales_with_discount,
    SUM(ci.total_sales_qty) AS total_qty
FROM 
    customer_info ci
JOIN 
    income_bracket ib ON ci.valid_zip_count > 0 
LEFT JOIN 
    promotion_summary ps ON ci.c_customer_sk % 5 = ps.promo_count 
WHERE 
    ci.store_count > 2 
GROUP BY 
    ci.gender, ci.marital_status, ib.income_category, ps.promo_count, ps.total_sales_with_discount
HAVING 
    SUM(ci.total_sales_qty) > (SELECT AVG(total_sales_qty) FROM customer_info)
ORDER BY 
    total_qty DESC, ci.gender NULLS LAST;
