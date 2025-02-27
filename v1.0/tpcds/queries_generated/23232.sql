
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sold_date_sk DESC) as rn,
        SUM(ws_sales_price) OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total_sales
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_open_date_sk < 10000
)

SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    COALESCE(SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 END), 0) AS female_customers,
    COALESCE(SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 END), 0) AS male_customers,
    MAX(rs.running_total_sales) AS max_sales,
    AVG(rs.running_total_sales) FILTER (WHERE rs.running_total_sales IS NOT NULL AND rs.running_total_sales > 0) AS avg_positive_sales
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND (c.c_birth_year BETWEEN 1980 AND 2000 OR c.c_first_name LIKE '%a%')
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_current_hdemo_sk IS NULL)
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(c.c_customer_sk) > 10
ORDER BY 
    num_customers DESC
FETCH FIRST 5 ROWS ONLY;
