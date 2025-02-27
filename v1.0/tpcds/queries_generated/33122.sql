
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rnk
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_demo_sk ORDER BY c.c_customer_sk) AS cust_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
top_sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales
    FROM 
        sales_data s
    WHERE 
        s.rnk <= 5
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ib.ib_income_band_sk, 0) AS income_band,
        SUM(ts.total_sales) AS total_spent
    FROM 
        customer_data c
    LEFT JOIN 
        top_sales ts ON c.c_customer_sk = ts.ws_item_sk
    LEFT JOIN 
        income_band ib ON ib.ib_lower_bound <= c.hd_income_band_sk AND ib.ib_upper_bound > c.hd_income_band_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, income_band
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.hd_buy_potential,
    COALESCE(SUM(hvc.total_spent), 0) AS total_spent,
    COUNT(ts.ws_item_sk) AS purchased_items
FROM 
    customer_data c
LEFT JOIN 
    high_value_customers hvc ON c.c_customer_sk = hvc.c_customer_sk
LEFT JOIN 
    top_sales ts ON ts.ws_item_sk = c.c_current_addr_sk
WHERE 
    c.c_birth_year > 1990 AND
    (c.cd_gender = 'F' OR c.cd_gender IS NULL)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, c.cd_gender, c.hd_buy_potential
ORDER BY 
    total_spent DESC
LIMIT 10;
