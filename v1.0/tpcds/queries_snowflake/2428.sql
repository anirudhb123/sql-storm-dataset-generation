
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1001 AND 1050
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_country ORDER BY cd.cd_purchase_estimate DESC) AS country_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
top_customers AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.ca_country
    FROM 
        customer_info ci
    WHERE 
        ci.country_rank <= 10
),
returned_sales AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amt) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs2.total_returns, 0) AS total_returns,
    COALESCE(rs.total_sales, 0) - COALESCE(rs2.total_returns, 0) AS net_sales,
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.ca_country
FROM 
    item i
LEFT JOIN 
    ranked_sales rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    returned_sales rs2 ON i.i_item_sk = rs2.wr_item_sk
JOIN 
    top_customers tc ON tc.c_customer_id IN (
        SELECT DISTINCT c.c_customer_id 
        FROM customer c
        WHERE c.c_current_addr_sk IN (
            SELECT ca.ca_address_sk 
            FROM customer_address ca 
            WHERE ca.ca_country = tc.ca_country
        )
    )
WHERE 
    (rs.total_sales - COALESCE(rs2.total_returns, 0)) > 5000
ORDER BY 
    net_sales DESC;
