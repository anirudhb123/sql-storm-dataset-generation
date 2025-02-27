
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_ranked AS (
    SELECT 
        si.ws_item_sk,
        SUM(si.total_sales) AS total_sales,
        RANK() OVER (PARTITION BY si.ws_item_sk ORDER BY SUM(si.total_sales) DESC) AS sales_rank
    FROM 
        sales_summary si
    GROUP BY 
        si.ws_item_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sr.total_sales,
    sr.sales_rank
FROM 
    customer_info ci
LEFT JOIN 
    sales_ranked sr ON ci.c_customer_sk = sr.ws_item_sk
JOIN 
    income_band ib ON ci.income_band = ib.ib_income_band_sk
WHERE 
    ci.cd_gender = 'F' 
    AND sr.total_sales > 1000
    AND ib.ib_upper_bound IS NOT NULL
ORDER BY 
    sr.sales_rank
LIMIT 50;
