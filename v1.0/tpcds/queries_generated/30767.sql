
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
HighSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS rank_by_sales
    FROM SalesData sd
    WHERE sd.total_quantity > (
        SELECT AVG(total_quantity) 
        FROM SalesData
    )
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        row_number() OVER (PARTITION BY ca.ca_city ORDER BY c.c_last_name) AS city_rank
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
),
StoreSalesTotals AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        AVG(ss_ext_sales_price) AS avg_store_sales,
        SUM(ss_ext_tax) AS total_tax
    FROM store_sales ss
    GROUP BY ss.s_store_sk
)
SELECT
    h.ws_item_sk,
    h.total_quantity,
    h.total_sales,
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    st.total_store_sales,
    st.avg_store_sales,
    st.total_tax
FROM HighSales h
JOIN CustomerInfo ci ON h.ws_item_sk IN (
    SELECT 
        ws_item_sk 
    FROM web_sales 
    WHERE ws_bill_customer_sk = ci.c_customer_sk
)
LEFT JOIN StoreSalesTotals st ON st.s_store_sk = (
    SELECT 
        ss_store_sk 
    FROM store_sales 
    WHERE ss_item_sk = h.ws_item_sk 
    LIMIT 1
)
WHERE h.rank_by_sales <= 10
ORDER BY h.total_sales DESC, ci.c_last_name, ci.c_first_name;
