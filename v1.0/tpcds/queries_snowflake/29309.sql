
WITH StringAggregates AS (
    SELECT 
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(c.c_email_address) AS upper_email,
        LOWER(c.c_preferred_cust_flag) AS customer_flag,
        LENGTH(c.c_email_address) AS email_length,
        COUNT(DISTINCT ca.ca_city) AS city_count,
        LISTAGG(DISTINCT ca.ca_state, ',') WITHIN GROUP (ORDER BY ca.ca_state) AS unique_states,
        LISTAGG(DISTINCT i.i_item_desc, ',') WITHIN GROUP (ORDER BY i.i_item_desc) AS purchased_items
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY c.c_first_name, c.c_last_name, c.c_email_address, c.c_preferred_cust_flag
),
FinalReport AS (
    SELECT 
        first_name,
        last_name,
        full_name,
        upper_email,
        customer_flag,
        email_length,
        city_count,
        unique_states,
        purchased_items
    FROM StringAggregates
    WHERE email_length > 0
)
SELECT 
    first_name,
    last_name,
    full_name,
    upper_email,
    customer_flag,
    email_length,
    city_count,
    unique_states,
    purchased_items
FROM FinalReport
ORDER BY city_count DESC, last_name ASC, first_name ASC
LIMIT 100;
