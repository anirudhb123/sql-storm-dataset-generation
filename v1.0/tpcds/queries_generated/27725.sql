
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_id) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), address_summary AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(ca.ca_address_sk) AS address_count,
        STRING_AGG(DISTINCT ca.ca_street_name, ', ') AS street_names
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_city, ca.ca_state
), recent_web_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = EXTRACT(YEAR FROM CURRENT_DATE) AND d.d_month_seq = EXTRACT(MONTH FROM CURRENT_DATE))
    GROUP BY 
        ws.ws_sold_date_sk
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    asumm.ca_city,
    asumm.ca_state,
    asumm.address_count,
    asumm.street_names,
    rws.total_sales,
    rws.total_orders
FROM 
    ranked_customers rc
JOIN 
    address_summary asumm ON rc.customer_rank <= 10
LEFT JOIN 
    recent_web_sales rws ON rws.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
ORDER BY 
    rc.customer_rank, rws.total_sales DESC;
