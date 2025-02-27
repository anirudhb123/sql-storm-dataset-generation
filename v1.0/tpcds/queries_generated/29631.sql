
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address,
        c.c_birth_month,
        c.c_birth_day,
        c.c_birth_year,
        CONCAT(SUBSTRING(c.c_current_addr_sk::text, 1, 5), '...', SUBSTRING(c.c_current_addr_sk::text, -5)) AS masked_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
purchase_info AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DATE(d.d_date) AS purchase_date
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_item_sk, DATE(d.d_date)
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM item i
),
ranked_purchases AS (
    SELECT 
        ci.full_name,
        ci.c_email_address,
        ci.ca_city,
        pi.total_quantity,
        pi.total_sales,
        ii.i_item_desc,
        ii.i_brand,
        ii.i_category,
        RANK() OVER (PARTITION BY ci.c_email_address ORDER BY pi.total_sales DESC) AS sales_rank
    FROM customer_info ci
    JOIN purchase_info pi ON ci.c_customer_sk = pi.ws_bill_customer_sk
    JOIN item_info ii ON pi.ws_item_sk = ii.i_item_sk
)

SELECT 
    rp.full_name,
    rp.c_email_address,
    rp.ca_city,
    rp.i_item_desc,
    rp.i_brand,
    rp.i_category,
    rp.total_quantity,
    rp.total_sales,
    rp.sales_rank
FROM ranked_purchases rp
WHERE rp.sales_rank <= 5
ORDER BY rp.full_name, rp.total_sales DESC;
