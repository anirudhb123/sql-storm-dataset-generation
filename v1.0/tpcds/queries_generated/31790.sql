
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_marital_status, 
        cd.cd_gender, 
        cd.cd_purchase_estimate,
        0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_marital_status, 
        cd.cd_gender, 
        cd.cd_purchase_estimate,
        ch.level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerHierarchy ch ON ch.c_customer_sk = c.c_customer_sk
)
SELECT 
    addr.ca_city,
    COUNT(DISTINCT ch.c_customer_sk) AS total_customers,
    AVG(ch.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN ch.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN ch.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN ch.cd_gender IS NULL THEN 1 ELSE 0 END) AS unknown_gender_count,
    ROUND(AVG(ch.cd_purchase_estimate) * 1.1, 2) AS inflated_avg_purchase_estimate
FROM CustomerHierarchy ch
LEFT JOIN customer_address addr ON addr.ca_address_sk = ch.c_current_addr_sk
WHERE addr.ca_state = 'CA'
GROUP BY addr.ca_city
HAVING COUNT(DISTINCT ch.c_customer_sk) > 10
ORDER BY total_customers DESC
LIMIT 5;

WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
TopSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.total_sales,
        sd.total_profit,
        DENSE_RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
)
SELECT 
    dd.d_date AS sale_date,
    ts.total_sales,
    ts.total_profit
FROM TopSales ts
JOIN date_dim dd ON ts.ws_sold_date_sk = dd.d_date_sk
WHERE ts.sales_rank <= 5
ORDER BY ts.total_sales DESC;

SELECT 
    w.w_warehouse_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(CASE WHEN ss.ss_quantity < 5 THEN ss.ss_net_profit ELSE 0 END) AS low_quantity_profit
FROM store_sales ss
JOIN warehouse w ON ss.ss_warehouse_sk = w.w_warehouse_sk
WHERE ss.ss_sold_date_sk = (SELECT MAX(ss_inner.ss_sold_date_sk) FROM store_sales ss_inner)
GROUP BY w.w_warehouse_name
HAVING SUM(ss.ss_net_profit) > 1000
ORDER BY total_sales DESC;

SELECT 
    i.i_item_id,
    i.i_item_desc,
    SUM(ws.ws_quantity) AS total_sold,
    MAX(ws.ws_sales_price) AS max_price,
    MIN(ws.ws_sales_price) AS min_price,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM item i
LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
WHERE i.i_current_price IS NOT NULL
GROUP BY i.i_item_id, i.i_item_desc
HAVING AVG(ws.ws_sales_price) > (SELECT AVG(ws_inner.ws_sales_price) FROM web_sales ws_inner)
ORDER BY total_sold DESC
LIMIT 10;
