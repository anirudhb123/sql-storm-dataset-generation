
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk, 
        ws.item_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
    GROUP BY ws.bill_customer_sk, ws.item_sk
),
TopSales AS (
    SELECT 
        rs.bill_customer_sk, 
        rs.item_sk,
        rs.total_sales
    FROM RankedSales rs
    WHERE rs.sales_rank <= 10
),
SalesWithPromotions AS (
    SELECT 
        ts.bill_customer_sk, 
        ts.item_sk, 
        ts.total_sales, 
        p.promo_name
    FROM TopSales ts
    LEFT JOIN promotion p ON ts.item_sk = p.p_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    sw.total_sales,
    COALESCE(sw.promo_name, 'No Promotion') AS promo_name,
    ca.ca_city,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM SalesWithPromotions sw
JOIN customer c ON sw.bill_customer_sk = c.c_customer_sk
JOIN store s ON sw.item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'Electronics')
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON sw.bill_customer_sk = ws.ws_ship_customer_sk
WHERE ca.ca_state = 'CA' AND sw.total_sales > 1000
GROUP BY c.c_first_name, c.c_last_name, sw.total_sales, sw.promo_name, ca.ca_city
HAVING COUNT(DISTINCT ws.ws_order_number) > 1
ORDER BY sw.total_sales DESC
