
WITH RECURSIVE CustomerPaths AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        1 AS path_level
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        cp.path_level + 1
    FROM 
        CustomerPaths cp
    JOIN 
        customer c ON cp.c_customer_sk = c.c_current_cdemo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cp.path_level < 5
), 
SalesStats AS (
    SELECT 
        COALESCE(ws.ws_bill_cdemo_sk, ss.ss_cdemo_sk) AS customer_demo_sk,
        SUM(ws.ws_net_profit) + SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_bill_customer_sk = ss.ss_customer_sk
    GROUP BY 
        customer_demo_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(css.total_profit) AS overall_profit,
    AVG(css.web_sales_count) AS avg_web_sales,
    AVG(css.store_sales_count) AS avg_store_sales,
    COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses,
    CONCAT(cd.cd_gender, ' - ', cd.cd_marital_status) AS customer_segment
FROM 
    SalesStats css
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = css.customer_demo_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = (
        SELECT 
            ca_address_sk 
        FROM 
            customer_address 
        WHERE 
            ca.city IN (SELECT DISTINCT city FROM customer_address WHERE ca_state = 'CA')
        LIMIT 1
    )
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
HAVING 
    overall_profit > (
        SELECT 
            AVG(total_profit) 
        FROM 
            SalesStats
    )
ORDER BY 
    overall_profit DESC
LIMIT 10;
