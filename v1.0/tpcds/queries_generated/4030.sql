
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN 10000 AND 20000
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        RANK() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY c.c_birth_year DESC) AS income_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        c.c_birth_year IS NOT NULL AND
        cd.cd_marital_status = 'M'
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    s.ws_order_number,
    s.ws_sales_price,
    CASE 
        WHEN s.ws_sales_price IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status,
    COUNT(*) OVER (PARTITION BY ci.hd_income_band_sk) AS total_customers_in_income_band
FROM 
    RankedSales s
JOIN 
    CustomerInfo ci ON s.web_site_sk = ci.hd_income_band_sk
WHERE 
    ci.income_rank <= 5
ORDER BY 
    s.ws_sales_price DESC, 
    ci.c_last_name,
    ci.c_first_name;
