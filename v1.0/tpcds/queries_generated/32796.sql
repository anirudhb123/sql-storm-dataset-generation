
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_quantity > 0
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        cs_order_number,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk DESC) AS rn
    FROM catalog_sales
    WHERE cs_quantity > 0
)
SELECT 
    ca_state,
    SUM(total_sales) AS total_sales_amount,
    AVG(total_sales) AS average_sales,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN c_customer_sk END) AS female_customers,
    COUNT(DISTINCT CASE WHEN cd_gender = 'M' THEN c_customer_sk END) AS male_customers,
    (SELECT COUNT(*) FROM (SELECT DISTINCT cd_demo_sk FROM customer_demographics) as demo) AS total_demographics,
    CASE 
        WHEN AVG(total_sales) IS NULL THEN 'No Sales'
        ELSE CASE 
            WHEN AVG(total_sales) > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END
    END AS sales_segment
FROM (
    SELECT 
        ws.bill_addr_sk,
        SUM(ws.net_paid_inc_tax) AS total_sales
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ws.sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY ws.bill_addr_sk
    HAVING SUM(ws.net_paid_inc_tax) IS NOT NULL
) AS sales_grouped
JOIN customer c ON sales_grouped.bill_addr_sk = c.c_current_addr_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN sales_hierarchy sh ON c.c_customer_sk = sh.ws_customer_sk OR c.c_customer_sk = sh.cs_customer_sk
GROUP BY ca_state
ORDER BY total_sales_amount DESC
LIMIT 10;
