
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
), 
address_analysis AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        STRING_AGG(DISTINCT c.c_city || ', ' || c.c_state, '; ') AS city_states
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
), 
state_sales AS (
    SELECT 
        ra.web_site_id,
        aa.ca_state AS sales_state,
        ra.total_sales
    FROM 
        ranked_sales ra
    LEFT JOIN 
        customer c ON ra.web_site_id = c.c_customer_id
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        address_analysis aa ON ca.ca_state = aa.ca_state
)
SELECT 
    ss.sales_state,
    SUM(ss.total_sales) AS total_sales_by_state,
    COUNT(DISTINCT ss.web_site_id) AS unique_websites,
    STRING_AGG(DISTINCT ss.web_site_id, ', ') AS websites_list
FROM 
    state_sales ss
GROUP BY 
    ss.sales_state
ORDER BY 
    total_sales_by_state DESC;
