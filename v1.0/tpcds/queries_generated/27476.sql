
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        SUBSTRING(c.c_email_address, CHARINDEX('@', c.c_email_address) + 1, LEN(c.c_email_address)) AS email_domain,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        c.c_email_address
),
IncomeBandSummary AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(ci.c_customer_sk) AS customer_count,
        AVG(ci.total_orders) AS avg_orders_per_customer,
        STRING_AGG(ci.full_name, '; ') AS customer_names
    FROM 
        CustomerInfo ci
    JOIN 
        household_demographics hd ON ci.cd_income_band_sk = hd.hd_income_band_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib_ib_lower_bound AS income_lower_bound,
    ib.ib_upper_bound AS income_upper_bound,
    is.customer_count,
    is.avg_orders_per_customer,
    is.customer_names
FROM 
    income_band ib
LEFT JOIN 
    IncomeBandSummary is ON ib.ib_income_band_sk = is.ib_income_band_sk
ORDER BY 
    ib.ib_income_band_sk;
