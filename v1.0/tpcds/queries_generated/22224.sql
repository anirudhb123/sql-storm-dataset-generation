
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependents,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > 0
    GROUP BY 
        ws.ws_item_sk
),
high_income_customers AS (
    SELECT 
        DISTINCT h.hd_demo_sk,
        h.hd_buy_potential,
        ic.ib_upper_bound
    FROM 
        household_demographics h
    JOIN 
        income_band ic ON h.hd_income_band_sk = ic.ib_income_band_sk
    WHERE 
        h.hd_buy_potential = 'High'
),
result AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.credit_rating,
        is.total_quantity_sold,
        is.total_sales,
        CASE
            WHEN is.total_sales IS NULL THEN 'No Sales'
            WHEN is.total_sales > 1000 THEN 'High Value Customer'
            ELSE 'Regular Customer'
        END AS customer_value,
        CASE 
            WHEN ci.dependents IS NULL THEN 'No Dependents' 
            WHEN ci.dependents > 3 THEN 'Large Family'
            ELSE 'Small Family'
        END AS family_size,
        ROW_NUMBER() OVER (ORDER BY is.total_sales DESC) AS ranking
    FROM 
        customer_info ci
    LEFT JOIN
        item_sales is ON ci.c_customer_sk = is.ws_item_sk
    LEFT JOIN
        high_income_customers h ON ci.c_current_cdemo_sk = h.hd_demo_sk
    WHERE 
        (ci.rn = 1 OR ci.credit_rating <> 'Poor')
)
SELECT 
    r.*,
    CASE 
        WHEN r.customer_value = 'High Value Customer' THEN 'VIP'
        ELSE 'Standard'
    END AS customer_category
FROM 
    result r
WHERE 
    r.total_quantity_sold > 10
ORDER BY 
    r.total_sales DESC
LIMIT 100;
