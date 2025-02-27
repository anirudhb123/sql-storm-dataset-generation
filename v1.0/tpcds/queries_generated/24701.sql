
WITH CustomerAnalytics AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ROW_NUMBER() OVER(PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
TopCustomers AS (
    SELECT 
        c.* 
    FROM 
        CustomerAnalytics c
    WHERE 
        c.city_rank <= 10
)
SELECT 
    ca.ca_city,
    COUNT(tc.c_customer_id) AS top_customers_count,
    AVG(tc.cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(CONCAT(tc.c_first_name, ' ', tc.c_last_name), '; ') AS customer_names
FROM 
    CustomerAnalytics ca
LEFT JOIN 
    TopCustomers tc ON ca.c_customer_id = tc.c_customer_id
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(tc.c_customer_id) > 0
ORDER BY 
    avg_purchase_estimate DESC 
LIMIT 5;

WITH RECURSIVE DateRange AS (
    SELECT 
        MIN(d_date) AS start_date,
        MAX(d_date) AS end_date
    FROM 
        date_dim
), 
SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) FILTER (WHERE ws.ws_net_profit IS NOT NULL) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    CROSS JOIN 
        DateRange dr
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_date BETWEEN start_date AND end_date) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date BETWEEN start_date AND end_date)
    GROUP BY 
        ws.web_site_id
)
SELECT 
    wd.web_site_id,
    wd.total_net_profit,
    CASE 
        WHEN wd.total_net_profit IS NULL THEN 'No Profit'
        WHEN wd.total_net_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    SalesData wd
WHERE 
    wd.total_net_profit IS NOT NULL
UNION ALL
SELECT 
    'Total/Overall' AS web_site_id,
    SUM(total_net_profit) AS total_net_profit,
    'Summary' AS profit_status
FROM 
    SalesData;
