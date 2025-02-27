
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM web_sales ws
    INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year < 1980
),
MaxSales AS (
    SELECT 
        web_site_sk,
        MAX(ws_sales_price) AS max_sales_price
    FROM RankedSales
    WHERE rank_sales <= 10
    GROUP BY web_site_sk
),
StoreInfo AS (
    SELECT 
        s.s_store_name,
        s.s_number_employees,
        s.s_floor_space,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_sales_quantity
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_name, s.s_number_employees, s.s_floor_space
)
SELECT 
    si.s_store_name,
    si.s_number_employees,
    si.s_floor_space,
    si.total_sales_quantity,
    ms.max_sales_price
FROM StoreInfo si
LEFT OUTER JOIN MaxSales ms ON si.s_floor_space > (SELECT AVG(s_floor_space) FROM store)
WHERE si.total_sales_quantity > 50
ORDER BY si.total_sales_quantity DESC, ms.max_sales_price DESC
LIMIT 20;
