
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CASE 
            WHEN hd_income_band_sk IS NULL THEN 'Unknown'
            ELSE ib_income_band_sk
        END AS income_band
    FROM 
        customer_demographics
    LEFT JOIN 
        household_demographics ON customer_demographics.cd_demo_sk = household_demographics.hd_demo_sk
),
top_items AS (
    SELECT 
        ws_item_sk,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
    WHERE 
        total_quantity > 100
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    td.ws_item_sk,
    sd.total_sales,
    sd.avg_profit,
    d.income_band
FROM 
    top_items td
JOIN 
    sales_data sd ON td.ws_item_sk = sd.ws_item_sk
JOIN 
    demographics d ON d.cd_demo_sk = (
        SELECT 
            c_current_cdemo_sk 
        FROM 
            customer 
        WHERE 
            c_customer_sk IN (
                SELECT 
                    ws_bill_customer_sk 
                FROM 
                    web_sales 
                WHERE 
                    ws_item_sk = td.ws_item_sk
            )
        LIMIT 1
    )
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk IN (
        SELECT 
            ws_ship_mode_sk 
        FROM 
            web_sales 
        WHERE 
            ws_item_sk = td.ws_item_sk
    )
WHERE 
    d.cd_gender IS NOT NULL 
    AND sm.sm_type IS NOT NULL
ORDER BY 
    sd.total_sales DESC, 
    d.cd_gender, 
    d.cd_marital_status;
