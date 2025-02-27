
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COALESCE(cd_dep_count, 0) AS dep_count
    FROM customer_demographics
)
SELECT 
    c.c_customer_id,
    ca.ca_address_id,
    cd.cd_gender,
    SUM(sd.total_quantity) AS quantity_sold,
    SUM(sd.total_sales) AS total_sales_amount,
    COUNT(DISTINCT CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_order_number END) AS catalog_sales_count,
    MAX(cd.dep_count) OVER (PARTITION BY c.c_customer_id) AS max_dependents
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN SalesData sd ON sd.ws_item_sk IN (
    SELECT wr_item_sk 
    FROM web_returns 
    WHERE wr_returned_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE)
)
LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state = 'CA' 
    AND cd.cd_marital_status = 'S' 
    AND (c.c_birth_year BETWEEN 1980 AND 1990 OR cd.cd_gender IS NULL)
GROUP BY 
    c.c_customer_id, 
    ca.ca_address_id, 
    cd.cd_gender
HAVING 
    SUM(sd.total_sales) > 1000
ORDER BY 
    total_sales_amount DESC
LIMIT 50;
