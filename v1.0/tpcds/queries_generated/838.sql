
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
),
HighValueItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales
    FROM RankedSales rs
    WHERE rs.rn <= 5
    GROUP BY rs.ws_item_sk
    HAVING SUM(rs.ws_sales_price * rs.ws_quantity) > (SELECT AVG(ws_sales_price) FROM web_sales)
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_country,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ca.ca_country
),
SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN HighValueItems hvi ON ws.ws_item_sk = hvi.ws_item_sk
    GROUP BY ws.ws_item_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ca_country,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_discount, 0) AS total_discount
FROM CustomerDetails cd
LEFT JOIN SalesDetails sd ON cd.c_customer_sk IN (
    SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk IN (SELECT ws_item_sk FROM HighValueItems)
)
ORDER BY cd.ca_country, total_sales DESC;
