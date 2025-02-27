
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS site_rank,
        DENSE_RANK() OVER (ORDER BY ws.ws_sales_price) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.web_site_sk) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) OVER (PARTITION BY ws.web_site_sk) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL AND 
        c.c_birth_year BETWEEN 1980 AND 1995
),
filtered_sales AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_sales_price,
        rs.ws_net_profit,
        rs.total_quantity,
        rs.order_count
    FROM 
        ranked_sales rs
    WHERE 
        rs.site_rank = 1 AND
        rs.price_rank < 10
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN ca.ca_country IS NULL THEN 'Unknown'
            ELSE ca.ca_country
        END AS country_info
    FROM 
        customer_address ca 
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        ca.ca_city IS NOT NULL
)
SELECT 
    fi.web_site_sk,
    fi.ws_sales_price,
    fi.ws_net_profit,
    ai.ca_city,
    ai.country_info,
    fi.total_quantity,
    fi.order_count
FROM 
    filtered_sales fi
JOIN 
    address_info ai ON fi.web_site_sk = ai.ca_address_sk
ORDER BY 
    fi.ws_net_profit DESC, fi.total_quantity DESC
LIMIT 100
UNION ALL
SELECT 
    ai.ca_address_sk AS web_site_sk,
    NULL AS ws_sales_price,
    NULL AS ws_net_profit,
    ai.ca_city,
    ai.country_info,
    0 AS total_quantity,
    0 AS order_count
FROM 
    address_info ai
WHERE 
    ai.ca_state IS NOT NULL AND 
    NOT EXISTS (
        SELECT 1 
        FROM filtered_sales fs 
        WHERE fs.web_site_sk = ai.ca_address_sk
    )
ORDER BY 
    country_info DESC;
