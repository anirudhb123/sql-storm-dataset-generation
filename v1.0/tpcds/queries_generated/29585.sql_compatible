
WITH AddressDetails AS (
    SELECT
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        COUNT(*) AS address_count
    FROM
        customer_address
    GROUP BY
        ca_state, ca_street_number, ca_street_name, ca_street_type
),
CustomerDetails AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS employed_dependents
    FROM
        customer_demographics
    JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY
        cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales AS ws
    JOIN web_site AS w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY
        ws.web_site_id
),
FinalBenchmark AS (
    SELECT
        ad.ca_state,
        ad.full_address,
        ad.address_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.customer_count,
        cd.total_dependents,
        cd.employed_dependents,
        ss.web_site_id,
        ss.total_sales,
        ss.order_count
    FROM
        AddressDetails AS ad
    JOIN CustomerDetails AS cd ON ad.address_count > 100 
    JOIN SalesSummary AS ss ON ss.total_sales > 1000 
)
SELECT
    ca_state,
    full_address,
    address_count,
    cd_gender,
    cd_marital_status,
    customer_count,
    total_dependents,
    employed_dependents,
    web_site_id,
    total_sales,
    order_count
FROM
    FinalBenchmark
ORDER BY
    address_count DESC, total_sales DESC;
