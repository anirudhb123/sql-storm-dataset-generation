
WITH RECURSIVE income_analysis AS (
    SELECT 
        hd.hd_demo_sk,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        NULLIF(MAX(TO_NUMBER(income.ib_upper_bound) / NULLIF(income.ib_lower_bound, 0)), 0) AS income_ratio
    FROM 
        household_demographics hd 
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band income ON hd.hd_income_band_sk = income.ib_income_band_sk
    GROUP BY 
        hd.hd_demo_sk
),
address_summary AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_city, ca.ca_state
),
sales_data AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
),
promotions AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        CASE WHEN COUNT(DISTINCT ws.ws_order_number) > 0 THEN 1 ELSE 0 END AS is_successful
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
    HAVING 
        COALESCE(SUM(ws.ws_net_profit), 0) > 1000
),
final_analysis AS (
    SELECT 
        ia.hd_demo_sk,
        ia.male_count,
        ia.female_count,
        asu.full_address,
        asu.customer_count,
        sd.total_quantity,
        sd.total_sales,
        pr.total_profit,
        pr.promo_sales_count,
        DENSE_RANK() OVER (ORDER BY pr.total_profit DESC) AS profit_rank
    FROM 
        income_analysis ia
    JOIN 
        address_summary asu ON ia.hd_demo_sk = asu.customer_count
    LEFT JOIN 
        sales_data sd ON ia.hd_demo_sk = sd.ws_item_sk
    LEFT JOIN 
        promotions pr ON sd.ws_item_sk = pr.p_promo_id
)
SELECT 
    *,
    CASE 
        WHEN total_sales IS NULL OR total_sales = 0 THEN 'No Sales' 
        ELSE 'Sales Recorded' 
    END AS sales_status,
    COALESCE(NULLIF((total_sales / NULLIF(customer_count, 0)), 0), 'N/A') AS sales_per_customer
FROM 
    final_analysis
WHERE 
    profit_rank <= 10
ORDER BY 
    profit_rank;
