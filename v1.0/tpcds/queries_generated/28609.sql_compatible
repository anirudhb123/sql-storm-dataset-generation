
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        CASE 
            WHEN ws.web_site_sk IS NOT NULL THEN 'Web'
            WHEN cs.cs_item_sk IS NOT NULL THEN 'Catalog'
            WHEN ss.ss_item_sk IS NOT NULL THEN 'Store'
            ELSE 'Unknown'
        END AS sales_channel,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales
    FROM RankedCustomers c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY sales_channel
)
SELECT 
    rs.full_name,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.cd_education_status,
    ss.sales_channel,
    ss.customer_count,
    ss.total_orders,
    ss.total_sales
FROM RankedCustomers rs
JOIN SalesSummary ss ON rs.c_customer_sk = ss.customer_count
ORDER BY ss.total_sales DESC
LIMIT 100;
