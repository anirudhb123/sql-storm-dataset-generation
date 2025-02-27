
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
SalesData AS (
    SELECT 
        ws.ws_web_site_sk,
        ws.ws_order_number,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_web_site_sk, ws.ws_order_number
), 
ProfileSummary AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        s.total_quantity,
        s.total_sales,
        RANK() OVER (PARTITION BY cd.ca_country ORDER BY s.total_sales DESC) AS sales_rank
    FROM CustomerDetails cd
    JOIN SalesData s ON cd.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    ps.full_name,
    ps.ca_city,
    ps.ca_state,
    ps.ca_country,
    ps.total_quantity,
    ps.total_sales,
    ps.sales_rank
FROM ProfileSummary ps
WHERE ps.sales_rank <= 10
ORDER BY ps.ca_country, ps.sales_rank;
