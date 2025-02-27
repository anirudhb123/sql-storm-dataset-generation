
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
CustomerStats AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT cd_demo_sk) AS demo_count,
        MAX(c_birth_year) AS max_birth_year
    FROM 
        customer
        JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        c_birth_year IS NOT NULL
    GROUP BY 
        c_customer_sk
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(sd.total_quantity) AS total_sales_quantity,
    SUM(sd.total_sales) AS total_sales_value,
    COALESCE(SUM(rs.total_returned), 0) AS total_returns,
    AVG(cs.demo_count) AS avg_demo_per_customer,
    STRING_AGG(DISTINCT CONCAT(COALESCE(c.c_last_name, 'Unknown'), ', ', COALESCE(cs.max_birth_year, 0)::text), '; ') AS customer_names
FROM 
    customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_item_sk OR c.c_customer_sk = sd.cs_item_sk
    LEFT JOIN ReturnStats rs ON c.c_customer_sk = rs.sr_customer_sk
    JOIN CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
WHERE 
    ca_state IS NOT NULL
GROUP BY 
    ca_state
HAVING 
    SUM(sd.total_sales) > 1000
ORDER BY 
    customer_count DESC, total_sales_value DESC;
