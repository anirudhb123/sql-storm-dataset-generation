
WITH address_stats AS (
    SELECT 
        ca_state,
        COUNT(*) AS addr_count,
        LISTAGG(ca_city, ', ' ORDER BY ca_city) AS city_list,
        LISTAGG(DISTINCT ca_street_name, ', ' ORDER BY ca_street_name) AS street_name_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
), 
customer_stats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        LISTAGG(DISTINCT cd_education_status, ', ' ORDER BY cd_education_status) AS education_levels
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
), 
sales_summary AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_quantity) AS avg_quantity_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    a.ca_state,
    a.addr_count,
    a.city_list,
    a.street_name_list,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    c.education_levels,
    s.total_net_profit,
    s.avg_quantity_sold
FROM 
    address_stats a
JOIN 
    customer_stats c ON a.addr_count > 100
JOIN 
    sales_summary s ON a.addr_count = s.ws_bill_addr_sk
ORDER BY 
    a.addr_count DESC, c.customer_count DESC;
