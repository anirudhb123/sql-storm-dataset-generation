
WITH customer_performance AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as purchase_rank,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        COALESCE(SUM(cr_return_quantity), 0) AS catalog_returns,
        COUNT(DISTINCT wr_order_number) AS web_returns_count,
        SUM(ws_net_paid) AS total_web_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
), high_value_customers AS (
    SELECT c_customer_id, c_first_name, c_last_name, cd_gender, cd_marital_status, purchase_rank, total_returns, catalog_returns, web_returns_count, total_web_sales
    FROM customer_performance
    WHERE purchase_rank = 1 AND total_web_sales > 1000
), address_details AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        a.total_web_sales
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    INNER JOIN high_value_customers a ON c.c_customer_id = a.c_customer_id
), customer_summary AS (
    SELECT 
        ad.ca_address_id,
        ad.ca_city,
        ad.ca_state,
        ad.ca_country,
        COUNT(DISTINCT hvc.c_customer_id) AS number_of_customers,
        SUM(hvc.total_web_sales) AS total_sales,
        AVG(hvc.total_returns) AS avg_returns,
        MAX(hvc.web_returns_count) AS max_web_returns
    FROM address_details ad
    JOIN high_value_customers hvc ON ad.total_web_sales = hvc.total_web_sales
    GROUP BY ad.ca_address_id, ad.ca_city, ad.ca_state, ad.ca_country
)
SELECT 
    cs.ca_address_id,
    cs.ca_city,
    COALESCE(NULLIF(cs.number_of_customers, 0), 1) AS safe_customer_count,
    cs.total_sales / NULLIF(cs.number_of_customers, 0) AS avg_sales_per_customer,
    cs.avg_returns,
    CASE 
        WHEN cs.max_web_returns > 0 THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_rate_description,
    LISTAGG(c.c_first_name || ' ' || c.c_last_name, ', ') WITHIN GROUP (ORDER BY c.c_first_name, c.c_last_name) AS customer_names
FROM customer_summary cs
LEFT JOIN high_value_customers c ON cs.number_of_customers > 0
GROUP BY cs.ca_address_id, cs.ca_city, cs.number_of_customers, cs.total_sales, cs.avg_returns, cs.max_web_returns
ORDER BY cs.total_sales DESC;
