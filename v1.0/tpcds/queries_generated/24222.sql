
WITH AddressCounts AS (
    SELECT ca_state, COUNT(DISTINCT ca_address_sk) AS total_addresses
    FROM customer_address
    WHERE ca_country IS NOT NULL
    GROUP BY ca_state
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        NULLIF(SUM(ws.ws_ext_sales_price), 0) AS total_sales_amount
    FROM web_sales ws
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ws.ws_item_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(sd.total_quantity_sold) AS total_quantity_sold,
    COALESCE(NULLIF(SUM(sd.total_sales_amount), 0), 1) AS total_sales_non_zero,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(DISTINCT c.c_customer_sk) DESC) AS rank_by_customer_count,
    RANK() OVER (ORDER BY total_quantity_sold DESC) AS overall_sales_rank
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN SalesData sd ON c.c_customer_sk IN (
        SELECT ws_bill_customer_sk
        FROM web_sales
        WHERE ws_item_sk = sd.ws_item_sk
    )
LEFT JOIN AddressCounts ac ON ac.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = c.c_current_addr_sk)
WHERE cd_cd_demo_sk BETWEEN (SELECT MIN(cd_demo_sk) FROM customer_demographics) AND (SELECT MAX(cd_demo_sk) FROM customer_demographics)
    AND cd.cd_marital_status IN ('M', 'S')
GROUP BY cd.cd_gender, cd.cd_marital_status
HAVING COUNT(DISTINCT c.c_customer_sk) > 
    (SELECT AVG(total_customers) FROM (
        SELECT COUNT(DISTINCT c.c_customer_sk) AS total_customers
        FROM customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        GROUP BY cd.cd_gender
    ) AS avg_customers)
ORDER BY total_quantity_sold DESC, cd.cd_gender ASC;
