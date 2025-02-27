
WITH RECURSIVE sales_ranking AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_quantity DESC) as rn
    FROM 
        web_sales
), aggregated_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), unmatched_sales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_catalog_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
    EXCEPT 
    SELECT 
        ws_item_sk,
        SummerDay AS total_catalog_sales 
    FROM 
        aggregated_sales
), customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), sales_analysis AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        SUM(ws.ws_quantity) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit,
        MAX(ws.ws_sales_price) AS max_web_sales_price,
        MIN(ws.ws_sales_price) AS min_web_sales_price,
        CASE 
            WHEN ci.income_band IS NULL THEN 'Unknown' 
            ELSE 'Known' 
        END AS income_status
    FROM 
        customer_info ci
    JOIN 
        web_sales ws ON ci.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, ci.income_band
)
SELECT 
    sa.c_customer_id,
    sa.cd_gender,
    sa.cd_marital_status,
    sa.total_web_sales,
    sa.total_web_profit,
    sa.income_status,
    sr.ws_item_sk,
    sr.rn
FROM 
    sales_analysis sa
LEFT JOIN 
    sales_ranking sr ON sa.total_web_sales > 0
WHERE 
    sa.total_web_sales > 100
  AND 
    sr.rn <= 5
ORDER BY 
    sa.total_web_profit DESC, sa.c_customer_id;
