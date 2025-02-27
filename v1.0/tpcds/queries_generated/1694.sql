
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_ship_date_sk,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        SUM(ws_sales_price) OVER (PARTITION BY ws_item_sk) AS total_sales
    FROM web_sales
    WHERE ws_sales_price > 20.00
),
TopSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.price_rank,
        rs.total_sales,
        cd.cd_gender,
        ca.ca_city
    FROM RankedSales rs
    LEFT JOIN customer c ON c.c_customer_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_order_number = rs.ws_order_number LIMIT 1))
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE rs.price_rank = 1
)
SELECT 
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    COUNT(DISTINCT ts.ws_order_number) AS order_count,
    SUM(ts.ws_sales_price) AS total_revenue,
    COUNT(DISTINCT ts.ca_city) AS unique_cities
FROM TopSales ts
GROUP BY cd.cd_gender
HAVING SUM(ts.total_sales) > 1000.00
ORDER BY total_revenue DESC
UNION ALL
SELECT 
    'Overall' AS gender,
    COUNT(DISTINCT ws_order_number),
    SUM(ws_sales_price),
    COUNT(DISTINCT ca_city)
FROM web_sales ws
LEFT JOIN customer_address ca ON ws_bill_addr_sk = ca.ca_address_sk
WHERE ws_ship_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
  AND ws_sales_price > 15.00
ORDER BY total_revenue DESC
LIMIT 10;
