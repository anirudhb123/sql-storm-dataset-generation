
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
IncomeStats AS (
    SELECT 
        cd.cd_income_band_sk,
        COUNT(*) AS customer_count,
        STRING_AGG(c.customer_id, ', ') AS customer_ids
    FROM 
        customer c
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cd.cd_income_band_sk
),
SalesSummary AS (
    SELECT 
        s.ss_store_sk,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_revenue
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.ss_store_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ISNULL(ib.ib_lower_bound, 'Unknown') AS income_range,
    ISNULL(is.customer_count, 0) AS num_customers,
    ss.total_sales,
    ss.total_revenue
FROM 
    CustomerInfo ci
LEFT JOIN 
    IncomeStats is ON ci.c_customer_id = ANY(STRING_TO_ARRAY(is.customer_ids, ', '))
LEFT JOIN 
    SalesSummary ss ON ss.ss_store_sk = ci.c_current_addr_sk
ORDER BY 
    ci.ca_city, ci.ca_state, total_revenue DESC;
