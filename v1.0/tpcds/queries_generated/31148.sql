
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
    UNION ALL
    SELECT 
        ch.c_customer_sk,
        ch.c_customer_id,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_addr_sk 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
),
AddressCounts AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'USA'
    GROUP BY ca.ca_state
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY ws.ws_sold_date_sk
),
TopPromotion AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_name
    ORDER BY total_revenue DESC
    LIMIT 1
)
SELECT 
    ch.c_customer_id,
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_gender,
    ac.customer_count,
    sd.total_sales,
    td.total_revenue
FROM CustomerHierarchy ch
LEFT JOIN AddressCounts ac ON ch.c_customer_sk = ac.customer_count
LEFT JOIN SalesData sd ON sd.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
CROSS JOIN TopPromotion td
WHERE ch.level <= 3;
