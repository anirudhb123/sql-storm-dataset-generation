
WITH SalesData AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY ws.web_site_sk
),
StoreData AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_ext_discount_amt) AS store_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY ss.s_store_sk
),
AggregateData AS (
    SELECT 
        COALESCE(SD.s_store_sk, 0) AS store_sk,
        COALESCE(SD.store_sales, 0) AS total_store_sales,
        COALESCE(SD.store_discount, 0) AS total_store_discount,
        COALESCE(SD.store_orders, 0) AS total_store_orders,
        COALESCE(SD.total_sales, 0) AS total_web_sales,
        COALESCE(SD.total_discount, 0) AS total_web_discount,
        COALESCE(SD.total_orders, 0) AS total_web_orders
    FROM StoreData SD
    FULL OUTER JOIN SalesData WD ON SD.s_store_sk = WD.web_site_sk
)
SELECT 
    store_sk,
    total_store_sales,
    total_store_discount,
    total_store_orders,
    total_web_sales,
    total_web_discount,
    total_web_orders
FROM AggregateData
ORDER BY store_sk;
