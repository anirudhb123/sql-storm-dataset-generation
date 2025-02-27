
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 0 AS level
    FROM customer c
    WHERE c.c_customer_sk = 1
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_customer_sk = ch.c_customer_sk + 1
),
AddressInfo AS (
    SELECT DISTINCT ca.ca_city, ca.ca_state, COUNT(c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_city, ca.ca_state
),
SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year IN (2021, 2022)
    GROUP BY d.d_year
),
RankedSales AS (
    SELECT *,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesSummary
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ai.ca_city,
    ai.ca_state,
    r.total_sales,
    r.order_count,
    (CASE 
        WHEN r.sales_rank <= 5 THEN 'Top 5%' 
        ELSE 'Others' 
     END) AS sales_category
FROM CustomerHierarchy ch
JOIN AddressInfo ai ON ai.customer_count > 10
JOIN RankedSales r ON r.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE ai.ca_state IS NOT NULL
  AND (r.total_sales > 10000 OR r.order_count > 50)
ORDER BY sales_category, total_sales DESC;
