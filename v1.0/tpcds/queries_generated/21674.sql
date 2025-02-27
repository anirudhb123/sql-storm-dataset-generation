
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL AND
        ws.ws_quantity > 0
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IN ('M', 'F') AND 
        cd.cd_purchase_estimate > 1000
),
income_ranges AS (
    SELECT 
        ib.ib_income_band_sk,
        CASE 
            WHEN i_band.ib_lower_bound IS NULL OR i_band.ib_upper_bound IS NULL THEN 'UNKNOWN'
            ELSE CONCAT('$', CAST(i_band.ib_lower_bound AS VARCHAR), ' - $', CAST(i_band.ib_upper_bound AS VARCHAR))
        END AS income_range
    FROM 
        income_band i_band
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ri.income_range,
    COUNT(DISTINCT rs.ws_order_number) AS total_orders,
    SUM(rs.ws_ext_sales_price) AS total_sales,
    AVG(rs.ws_ext_sales_price) AS avg_sales_price,
    (SELECT COUNT(*) FROM store s WHERE s.s_country = 'USA') AS total_stores,
    (SELECT COUNT(DISTINCT wr.wr_order_number) 
     FROM web_returns wr 
     WHERE wr.wr_return_quantity < 0) AS negative_returns
FROM 
    customer_info ci
LEFT JOIN 
    ranked_sales rs ON ci.c_customer_sk = rs.ws_item_sk
LEFT JOIN 
    income_ranges ri ON ci.cd_purchase_estimate BETWEEN ri.ib_income_band_sk AND ri.ib_income_band_sk
GROUP BY 
    ci.c_first_name, ci.c_last_name, ci.cd_gender, ri.income_range
HAVING 
    SUM(rs.ws_ext_sales_price) > 5000 AND
    COUNT(DISTINCT rs.ws_order_number) > 10
ORDER BY 
    total_sales DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM customer_info) * 0.1;
