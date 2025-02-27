
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk AS addr_sk, ca_city, ca_county, ca_state, 0 AS level
    FROM customer_address
    WHERE ca_state = 'CA'
    
    UNION ALL
    
    SELECT a.ca_address_sk, a.ca_city, a.ca_county, a.ca_state, ah.level + 1
    FROM customer_address a
    JOIN address_hierarchy ah ON a.ca_county = ah.ca_county AND a.ca_state = ah.ca_state
    WHERE ah.level < 5
), 
monthly_sales AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_year, d.d_month_seq
), 
demographic_summary AS (
    SELECT 
        cd.cd_gender,
        SUM(ws.ws_net_sales) AS total_gender_sales,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY cd.cd_gender
)
SELECT 
    d.d_year,
    d.d_month_seq,
    COALESCE(ms.total_sales, 0) AS monthly_sales,
    COALESCE(ms.order_count, 0) AS order_count,
    das.cd_gender,
    das.total_gender_sales,
    das.customer_count,
    STRING_AGG(DISTINCT ah.ca_city, ', ') AS cities_in_county
FROM monthly_sales ms
FULL OUTER JOIN demographic_summary das ON ms.d_year = das.d_year AND ms.d_month_seq = das.d_month_seq
LEFT JOIN address_hierarchy ah ON ah.ca_state = 'CA'
WHERE das.customer_count IS NOT NULL OR ms.order_count IS NOT NULL
GROUP BY d.d_year, d.d_month_seq, das.cd_gender
HAVING COUNT(ah.addr_sk) >= 2 AND ms.total_sales > ALL (SELECT AVG(total_sales) FROM monthly_sales WHERE d_year = ms.d_year)
ORDER BY d.d_year DESC, d.d_month_seq ASC;
