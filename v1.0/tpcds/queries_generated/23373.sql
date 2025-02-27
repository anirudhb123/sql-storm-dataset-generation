
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
top_sales AS (
    SELECT 
        ws_item_sk,
        SUM(CASE WHEN price_rank = 1 THEN ws_sales_price END) AS top_price,
        COUNT(*) AS total_sales
    FROM 
        ranked_sales
    GROUP BY 
        ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'UNKNOWN'
            ELSE ib.ib_income_band_sk
        END AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
store_data AS (
    SELECT 
        s.s_store_id,
        COUNT(ss.ss_item_sk) AS items_sold,
        SUM(ss.ss_sales_price) AS total_sales_amount
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(ts.top_price, 0) AS highest_web_price,
    COALESCE(sd.total_sales_amount, 0) AS store_sales,
    CASE 
        WHEN sd.items_sold > 100 THEN 'HIGH PERFORMER'
        WHEN sd.items_sold BETWEEN 50 AND 100 THEN 'AVERAGE'
        ELSE 'LOW PERFORMER'
    END AS performance_category
FROM 
    customer_data cd
LEFT JOIN 
    top_sales ts ON ts.ws_item_sk IN (SELECT ws_item_sk FROM ranked_sales)
LEFT JOIN 
    store_data sd ON sd.s_store_id = (SELECT s.s_store_id FROM store s ORDER BY random() LIMIT 1)
WHERE 
    cd.cd_gender IS NOT NULL
    AND cd.cd_marital_status IS NOT NULL
    AND (cd.income_band IS NOT NULL OR cd.income_band = 'UNKNOWN')
ORDER BY 
    COALESCE(ts.top_price, 0) DESC, 
    performance_category;
