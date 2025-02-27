
WITH AddressWords AS (
    SELECT
        ca_address_sk,
        REGEXP_SPLIT_TO_TABLE(ca_street_name, ' ') AS street_word
    FROM customer_address
),
WordCounts AS (
    SELECT
        street_word,
        COUNT(*) AS word_count
    FROM AddressWords
    GROUP BY street_word
),
StringProcessing AS (
    SELECT
        b.c_customer_id,
        b.c_first_name,
        b.c_last_name,
        b.c_email_address,
        a.street_word,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        wc.word_count
    FROM customer b
    JOIN customer_address a ON b.c_current_addr_sk = a.ca_address_sk
    JOIN warehouse w ON a.ca_city = w.w_city AND a.ca_state = w.w_state
    JOIN WordCounts wc ON wc.street_word = a.ca_street_name
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_email_address,
    COUNT(DISTINCT s.ws_order_number) AS total_orders,
    SUM(s.ws_sales_price) AS total_spent,
    STRING_AGG(DISTINCT w.w_warehouse_name, ', ') AS warehouse_names,
    MAX(wc.word_count) AS max_word_count
FROM StringProcessing c
LEFT JOIN web_sales s ON c.c_customer_id = s.ws_bill_customer_sk
LEFT JOIN warehouse w ON c.w_warehouse_name = w.w_warehouse_name
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, c.c_email_address
ORDER BY total_spent DESC
LIMIT 100;
