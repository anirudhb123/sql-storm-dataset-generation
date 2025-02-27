
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_item_sk
),
address_summary AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer_address
    LEFT JOIN customer ON ca_address_sk = c_current_addr_sk
    GROUP BY ca_address_sk, ca_city, ca_state
),
income_distribution AS (
    SELECT 
        hd_income_band_sk,
        COUNT(hd_demo_sk) AS household_count
    FROM household_demographics
    GROUP BY hd_income_band_sk
),
item_categories AS (
    SELECT 
        i_item_sk,
        i_category,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY i_current_price DESC) AS price_rank
    FROM item
    WHERE i_current_price IS NOT NULL
),
item_top_categories AS (
    SELECT 
        category,
        i_item_sk,
        total_quantity,
        total_sales
    FROM (
        SELECT 
            ic.i_category AS category,
            ss.ws_item_sk,
            ss.total_quantity,
            ss.total_sales,
            ROW_NUMBER() OVER (PARTITION BY ic.i_category ORDER BY ss.total_sales DESC) AS rank
        FROM sales_summary ss
        JOIN item_categories ic ON ss.ws_item_sk = ic.i_item_sk
    ) ranked
    WHERE rank <= 5
)
SELECT 
    a.ca_city,
    a.ca_state,
    COALESCE(id.household_count, 0) AS total_households,
    COALESCE(ss.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ss.total_sales, 0) AS total_sales_amount,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    STRING_AGG(DISTINCT it.category || ': ' || it.total_sales ORDER BY it.total_sales DESC) AS top_categories_sales
FROM address_summary a
LEFT JOIN sales_summary ss ON a.customer_count > 0
LEFT JOIN customer AS c ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN item_top_categories it ON it.total_sales > 0
LEFT JOIN income_distribution id ON a.customer_count > 0
GROUP BY a.ca_city, a.ca_state
ORDER BY total_sales_amount DESC
LIMIT 10;
