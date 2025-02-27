
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS ranking
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2457750 AND 2457800
),
AggregateSales AS (
    SELECT
        r.web_site_sk,
        SUM(r.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT r.ws_order_number) AS order_count
    FROM RankedSales r
    WHERE r.ranking <= 10
    GROUP BY r.web_site_sk
),
CustomerSummary AS (
    SELECT 
        ca.ca_state AS state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_state
)
SELECT
    a.web_site_sk,
    a.total_sales,
    a.order_count,
    COALESCE(cs.customer_count, 0) AS total_customers,
    COALESCE(cs.avg_purchase_estimate, 0) AS avg_customer_purchase_estimate,
    (CASE 
        WHEN a.total_sales > 10000 THEN 'High Selling'
        WHEN a.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Selling'
        ELSE 'Low Selling'
     END) AS sales_category
FROM AggregateSales a
LEFT JOIN CustomerSummary cs ON a.web_site_sk = cs.state
ORDER BY a.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
