
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM
        web_sales
    GROUP BY
        ws_item_sk
), 
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
    SUM(COALESCE(s.total_sales, 0)) AS total_sales,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM
    customer_address ca
LEFT JOIN
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN
    CustomerDetails cd ON c.c_customer_sk = cd.c_customer_sk
LEFT JOIN
    SalesCTE s ON cd.c_customer_sk = s.ws_item_sk
WHERE
    ca.ca_state IN ('CA', 'TX', 'NY')
GROUP BY
    ca.ca_city, ca.ca_state
HAVING
    COUNT(DISTINCT cd.c_customer_sk) > 5
ORDER BY
    total_sales DESC;
