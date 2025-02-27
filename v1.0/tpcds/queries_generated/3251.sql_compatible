
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 10) 
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 10 AND d_dom = 31)
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
), CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) AS city_rank
    FROM 
        customer_address ca
    WHERE 
        ca.ca_country = 'USA'
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(ca.ca_city, 'Unknown City') AS city,
    COALESCE(ca.ca_state, 'Unknown State') AS state,
    SUM(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price ELSE 0 END) AS total_web_sales,
    SUM(CASE WHEN ss.ss_sales_price IS NOT NULL THEN ss.ss_sales_price ELSE 0 END) AS total_store_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
    (SELECT 
        COUNT(DISTINCT cc.cc_call_center_sk) 
     FROM 
        call_center cc 
     WHERE 
        cc.cc_country = 'USA' 
        AND cc.cc_employees > 50) AS large_call_centers
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 2000
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_email_address IS NOT NULL)
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_sales_price) > 5000 OR SUM(ss.ss_sales_price) > 7000
ORDER BY 
    total_web_sales DESC, total_store_sales DESC;
