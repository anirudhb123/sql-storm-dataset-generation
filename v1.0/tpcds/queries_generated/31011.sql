
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 0 AS level
    FROM customer_address 
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, CONCAT(ch.ca_city, ' -> ', ca.ca_city), ca.ca_state, ca.ca_country, level + 1
    FROM customer_address ca
    JOIN address_hierarchy ch ON LEFT(ch.ca_city, 4) = LEFT(ca.ca_city, 4) AND ch.level < 2
),
ranked_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_current_addr_sk IS NOT NULL
    GROUP BY ws.web_site_id
),
null_check AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_sales_price,
        COALESCE(cs.cs_sales_price, 0) AS adjusted_price,
        CASE 
            WHEN r.r_reason_desc IS NOT NULL THEN 'Return Reason Exists'
            ELSE 'No Return Reason'
        END AS return_status
    FROM catalog_sales cs
    LEFT JOIN reason r ON cs.cs_coupon_amt = r.r_reason_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    SUM(s.total_sales) AS total_sales,
    COUNT(DISTINCT s.web_site_id) AS site_count,
    AVG(n.adjusted_price) AS average_price,
    MAX(n.return_status) as max_return_status
FROM address_hierarchy a
LEFT JOIN ranked_sales s ON a.ca_city = s.web_site_id
LEFT JOIN null_check n ON s.web_site_id = n.cs_order_number
WHERE a.level < 2
GROUP BY a.ca_city, a.ca_state
HAVING COUNT(DISTINCT s.web_site_id) > 1 AND AVG(n.adjusted_price) IS NOT NULL
ORDER BY total_sales DESC;
