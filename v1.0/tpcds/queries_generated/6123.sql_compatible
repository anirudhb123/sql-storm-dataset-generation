
WITH CustomerActivity AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_items_purchased,
        SUM(ws.ws_ext_sales_price) AS total_spending,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages_visited
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        c.c_customer_id
),
DemographicDetails AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        hd.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS demographic_count
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, hd.hd_income_band_sk
),
CustomerAnalysis AS (
    SELECT 
        a.c_customer_id,
        a.total_items_purchased,
        a.total_spending,
        a.total_orders,
        a.unique_web_pages_visited,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.ca_city,
        d.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY d.hd_income_band_sk ORDER BY a.total_spending DESC) AS income_rank
    FROM 
        CustomerActivity a
    JOIN 
        DemographicDetails d ON a.c_customer_id = d.c_customer_id
)

SELECT 
    *,
    CASE 
        WHEN income_rank <= 10 THEN 'Top 10% Income Band'
        WHEN income_rank <= 50 THEN 'Top 50% Income Band'
        ELSE 'Bottom Income Band'
    END AS income_band_label
FROM 
    CustomerAnalysis
WHERE 
    total_orders > 5
ORDER BY 
    total_spending DESC;
