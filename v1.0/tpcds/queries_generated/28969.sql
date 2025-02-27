
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        c.customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN CustomerDetails c ON ws.ws_bill_customer_sk = CAST(c.c_customer_id AS INTEGER)
    GROUP BY c.customer_id
),
SalesRanked AS (
    SELECT 
        customer_id, 
        total_sales, 
        order_count,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesSummary
)
SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    ss.total_sales,
    ss.order_count,
    ss.sales_rank
FROM SalesRanked ss
JOIN CustomerDetails cs ON cs.c_customer_id = ss.customer_id
WHERE ss.sales_rank <= 100
ORDER BY ss.sales_rank;
