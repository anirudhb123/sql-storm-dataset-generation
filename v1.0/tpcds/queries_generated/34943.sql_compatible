
WITH RECURSIVE sales_ranking AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        s.total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_ranking s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE 
        s.sales_rank <= 10
),
address_info AS (
    SELECT 
        ca.ca_address_id, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country,
        CASE 
            WHEN ca.ca_city IS NULL THEN 'Unknown City'
            ELSE ca.ca_city
        END AS city_info
    FROM 
        customer_address ca
),
demographics_summary AS (
    SELECT 
        ib.ib_income_band_sk, 
        COUNT(DISTINCT cd.cd_demo_sk) AS demo_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    ai.ca_address_id,
    ai.city_info,
    ds.demo_count,
    tc.total_sales
FROM 
    top_customers tc
LEFT JOIN 
    address_info ai ON tc.c_customer_id = ai.ca_address_id
LEFT JOIN 
    demographics_summary ds ON tc.cd_income_band_sk = ds.ib_income_band_sk
WHERE 
    (tc.cd_marital_status = 'M' OR tc.cd_gender = 'F') 
    AND tc.total_sales > (
        SELECT 
            AVG(total_sales) FROM sales_ranking
    );
