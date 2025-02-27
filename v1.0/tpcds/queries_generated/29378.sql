
SELECT
    ca_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT SUM(ws_ext_sales_price), ', ') AS sales_by_item
FROM
    customer_address ca
JOIN
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE
    ca_city IS NOT NULL
    AND cd_cd_gender = 'F'
    AND cd_marital_status = 'M'
GROUP BY
    ca_city
ORDER BY
    total_customers DESC
LIMIT 10;
