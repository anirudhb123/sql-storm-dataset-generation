
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        d.d_year,
        cd.cd_gender, 
        cd.cd_marital_status, 
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_paid) DESC) as rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, d.d_year, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_customer_id,
        rc.d_year,
        rc.cd_gender,
        rc.cd_marital_status
    FROM ranked_customers rc
    WHERE rc.rank <= 10
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COALESCE(ca.ca_zip, 'Unknown') AS safe_zip
    FROM customer_address ca 
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE ca.ca_state IN ('CA', 'NY') OR ca.ca_country = 'USA'
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        i.i_item_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_ext_discount_amt) AS max_discount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ws.ws_item_sk, i.i_item_id
)
SELECT 
    tc.c_customer_id,
    ta.ca_city,
    ta.safe_zip,
    ss.i_item_id,
    ss.total_sales,
    ss.order_count,
    ss.max_discount,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN ss.total_sales > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer' 
    END AS customer_type,
    NULLIF(ss.max_discount, 0) AS effective_discount
FROM top_customers tc
JOIN customer_addresses ta ON tc.c_customer_sk = ta.ca_address_sk
LEFT JOIN sales_summary ss ON tc.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk)
WHERE tc.cd_gender = 'M' 
AND (ss.total_sales > 500 OR ss.i_item_id IS NULL)
ORDER BY tc.c_customer_id, ss.total_sales DESC;
