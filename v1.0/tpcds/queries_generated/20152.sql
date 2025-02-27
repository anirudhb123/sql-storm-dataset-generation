
WITH RECURSIVE income_data AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        CAST(NULL AS INTEGER) AS prev_income_band_sk,
        0 AS rank 
    FROM 
        income_band
    WHERE 
        ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        id.ib_income_band_sk,
        id.rank + 1
    FROM 
        income_band ib
    JOIN 
        income_data id ON ib.ib_lower_bound BETWEEN id.ib_upper_bound AND id.ib_upper_bound + 100
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(hd.hd_income_band_sk, 'Unknown') AS income_band,
        COUNT(DISTINCT r.r_reason_sk) AS reason_count
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN 
        reason r ON r.r_reason_sk = sr.sr_reason_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hd.hd_income_band_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ws.ws_sales_price) AS median_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_bill_customer_sk IS NOT NULL
    GROUP BY 
        ws.ws_bill_customer_sk
),
final_report AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        sd.total_profit,
        sd.order_count,
        sd.max_sales_price,
        sd.min_sales_price,
        sd.median_sales,
        id.prev_income_band_sk,
        id.ib_lower_bound,
        id.ib_upper_bound
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN 
        income_data id ON ci.income_band = id.ib_income_band_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.total_profit,
    fr.order_count,
    CASE 
        WHEN fr.total_profit IS NULL THEN 'No Sales'
        WHEN fr.total_profit > 1000 THEN 'High Value'
        ELSE 'Regular Customer'
    END AS customer_category,
    CONCAT('Income Band ', coalesce(fr.ib_lower_bound, 'Unknown'), ' - ', coalesce(fr.ib_upper_bound, 'Unknown')) AS income_band_range,
    fr.max_sales_price,
    fr.min_sales_price,
    fr.median_sales
FROM 
    final_report fr
WHERE 
    fr.cd_marital_status IN ('M', 'S') 
ORDER BY 
    fr.total_profit DESC NULLS LAST
LIMIT 100;
