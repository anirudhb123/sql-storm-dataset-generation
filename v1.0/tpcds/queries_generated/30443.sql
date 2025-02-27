
WITH RECURSIVE SalesTrend AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        1 AS level
    FROM web_sales
    GROUP BY ws_sold_date_sk
    UNION ALL
    SELECT
        st.ws_sold_date_sk,
        st.total_quantity + COALESCE(SUM(ws.ws_quantity), 0),
        st.total_profit + COALESCE(SUM(ws.ws_net_profit), 0),
        st.level + 1
    FROM SalesTrend st
    LEFT JOIN web_sales ws ON st.ws_sold_date_sk < ws.ws_sold_date_sk
    GROUP BY st.ws_sold_date_sk, st.total_quantity, st.total_profit, st.level
)
, CustomerDemographics AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender
)
SELECT
    ca.ca_state,
    SUM(ss.ss_quantity) AS total_store_sales,
    AVG(cd.avg_purchase_estimate) AS avg_purchase_per_customer,
    SUM(CASE WHEN ss.ss_sales_price > 100 THEN ss.ss_net_profit ELSE 0 END) AS high_value_profits,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    MAX(st.total_profit) AS peak_web_profit,
    STRING_AGG(DISTINCT CONCAT(cd.cd_gender, ' (', cd.customer_count, ' customers)'), '; ') AS customer_summary
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN CustomerDemographics cd ON 1=1
LEFT JOIN SalesTrend st ON 1=1
GROUP BY ca.ca_state
HAVING SUM(ss.ss_quantity) > 1000
ORDER BY total_store_sales DESC, ca.ca_state ASC;
