
WITH RECURSIVE customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_store_sales,
        (COALESCE(SUM(ws.ws_sales_price), 0) + COALESCE(SUM(cs.cs_sales_price), 0) + COALESCE(SUM(ss.ss_sales_price), 0)) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked_sales AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM customer_sales
),
address_info AS (
    SELECT
        ca.ca_address_sk,
        CONCAT(COALESCE(ca.ca_street_number, ''), ' ', COALESCE(ca.ca_street_name, ''), ' ', COALESCE(ca.ca_street_type, ''), ' ', COALESCE(ca.ca_suite_number, '')) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM customer_address ca
),
sales_and_address AS (
    SELECT
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_web_sales,
        r.total_catalog_sales,
        r.total_store_sales,
        r.total_sales,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip
    FROM ranked_sales r
    LEFT JOIN address_info a ON r.c_customer_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = r.c_customer_sk)
    WHERE r.sales_rank <= 10
)
SELECT
    *,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    CASE 
        WHEN total_catalog_sales IS NULL OR total_catalog_sales = 0 THEN 'No Catalog Purchases'
        ELSE 'Catalog Buyer'
    END AS purchase_type
FROM sales_and_address
ORDER BY total_sales DESC, c_last_name ASC NULLS LAST;
