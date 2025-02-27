
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        nd.ask,
        ca.ca_city,
        ca.ca_state
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN
        (SELECT 
            ca_address_sk, 
            COUNT(*) AS ask 
        FROM 
            customer_address 
        GROUP BY 
            ca_address_sk
        HAVING 
            COUNT(*) > 2) nd ON ca.ca_address_sk = nd.ca_address_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    rs.total_sales,
    rs.order_count,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Top Seller' 
        ELSE 'Regular Seller' 
    END AS seller_status,
    ci.ca_city,
    ci.ca_state
FROM
    ranked_sales rs
JOIN
    customer_info ci ON rs.ws_item_sk = (SELECT cs_item_sk FROM catalog_sales WHERE cs_order_number = (SELECT MIN(cs_order_number) FROM catalog_sales WHERE cs_item_sk = rs.ws_item_sk))
WHERE
    rs.total_sales > (SELECT AVG(total_sales) FROM ranked_sales)
ORDER BY
    rs.total_sales DESC, 
    ci.ca_state,
    ci.ca_city;
