
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    a.ca_city,
    a.ca_state,
    SUBSTRING_INDEX(a.ca_street_name, ' ', 1) AS first_street_word,
    LENGTH(a.ca_street_name) AS street_name_length,
    LEFT(c.c_email_address, LOCATE('@', c.c_email_address) - 1) AS email_prefix,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cs.cs_ext_sales_price) AS total_spent
FROM
    customer c
JOIN
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
WHERE
    a.ca_state IN ('CA', 'NY')
GROUP BY
    c.c_customer_id, full_name, a.ca_city, a.ca_state, first_street_word, street_name_length, email_prefix, cd.cd_gender, cd.cd_marital_status
HAVING
    total_spent > 1000
ORDER BY
    total_spent DESC
LIMIT 100;
