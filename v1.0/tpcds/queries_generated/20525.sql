
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country, ah.level + 1
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_state = ah.ca_state AND a.ca_country IS NOT NULL
    WHERE ah.level < 3
),
PurchaseData AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        pd.c_customer_sk,
        pd.total_sales,
        pd.order_count,
        pd.unique_items,
        RANK() OVER (ORDER BY pd.total_sales DESC) AS sales_rank
    FROM PurchaseData pd
    WHERE pd.total_sales > (
        SELECT AVG(total_sales) 
        FROM PurchaseData
    )
),
WarehouseList AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_gmt_offset,
        ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY w.w_warehouse_sq_ft DESC) AS rank
    FROM warehouse w
    WHERE w.w_gmt_offset IS NOT NULL
)
SELECT 
    ah.ca_city,
    ah.ca_state,
    SUM(COALESCE(hv.total_sales, 0)) AS total_sales,
    COUNT(DISTINCT hv.c_customer_sk) AS customer_count,
    wl.w_warehouse_name,
    AVG(wl.w_gmt_offset) AS avg_offset
FROM AddressHierarchy ah
LEFT JOIN HighValueCustomers hv ON hv.c_customer_sk IN (
    SELECT DISTINCT c.c_customer_sk 
    FROM customer c 
    WHERE c.c_current_addr_sk IS NOT NULL
)
JOIN WarehouseList wl ON wl.rank <= 2 AND wl.w_warehouse_sk IN (
    SELECT w.w_warehouse_sk 
    FROM warehouse w 
    WHERE w.w_city = ah.ca_city AND w.w_state = ah.ca_state
)
GROUP BY ah.ca_city, ah.ca_state, wl.w_warehouse_name
HAVING SUM(COALESCE(hv.total_sales, 0)) > (
    SELECT AVG(total_sales) 
    FROM HighValueCustomers
)
ORDER BY total_sales DESC, customer_count DESC;
