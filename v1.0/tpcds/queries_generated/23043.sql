
WITH SalesData AS (
    SELECT 
        coalesce(ws.ws_item_sk, cs.cs_item_sk, ss.ss_item_sk) AS item_sk,
        COALESCE(ws.ws_net_paid, cs.cs_net_paid, ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(cs.cs_ext_discount_amt) AS total_catalog_discount,
        SUM(ss.ss_ext_discount_amt) AS total_store_discount
    FROM web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    FULL OUTER JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk AND cs.cs_item_sk = ss.ss_item_sk
    GROUP BY coalesce(ws.ws_item_sk, cs.cs_item_sk, ss.ss_item_sk)
),
AverageSales AS (
    SELECT 
        item_sk,
        total_sales,
        AVG(total_sales) OVER (PARTITION BY item_sk) AS avg_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
),
HighSalesItems AS (
    SELECT 
        item_sk,
        total_sales,
        avg_sales,
        sales_rank
    FROM AverageSales
    WHERE total_sales IS NOT NULL AND total_sales > avg_sales
)
SELECT 
    h.item_sk,
    h.total_sales,
    h.avg_sales,
    h.sales_rank,
    CASE 
        WHEN h.sales_rank <= 5 THEN 'Top Performer'
        WHEN h.sales_rank BETWEEN 6 AND 10 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category,
    CONCAT('Sales of Item SK ', h.item_sk, ' ranks ', 
           CAST(h.sales_rank AS VARCHAR), 
           ' among all items.') AS performance_message,
    (SELECT 
        COUNT(DISTINCT c.c_customer_sk)
     FROM customer c 
     WHERE c.c_current_cdemo_sk IS NOT NULL AND 
           EXISTS (SELECT 1 FROM customer_demographics cd WHERE cd.cd_demo_sk = c.c_current_cdemo_sk AND cd.cd_gender = 'F')
    ) AS female_customers_count,
    NULLIF((SELECT 
                 SUM(ss.ss_net_profit) 
             FROM store_sales ss 
             WHERE ss.ss_item_sk = h.item_sk), 0) AS store_item_net_profit
FROM HighSalesItems h
ORDER BY h.sales_rank;
