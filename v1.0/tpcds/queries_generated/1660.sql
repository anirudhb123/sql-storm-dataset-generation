
WITH RankedSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS RankSales
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS TotalOrders,
        AVG(ws_sales_price) AS AvgOrderValue
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE
        c.c_birth_year < 1980
    GROUP BY
        c.c_customer_sk
)
SELECT
    ca.ca_address_sk,
    ca.ca_city,
    cd.cd_gender,
    cs.TotalOrders,
    cs.AvgOrderValue,
    SUM(CASE WHEN rs.RankSales <= 3 THEN rs.ws_sales_price ELSE 0 END) AS TopSalesTotal
FROM
    customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
JOIN RankedSales rs ON c.c_customer_sk IN (SELECT DISTINCT ws_ship_customer_sk FROM web_sales WHERE ws_item_sk = rs.ws_item_sk)
GROUP BY
    ca.ca_address_sk,
    ca.ca_city,
    cd.cd_gender,
    cs.TotalOrders,
    cs.AvgOrderValue
HAVING
    SUM(rs.ws_sales_price) > 500
ORDER BY
    TopSalesTotal DESC
LIMIT 100;
