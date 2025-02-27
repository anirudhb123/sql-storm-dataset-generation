
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
StoreSalesSummary AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS number_of_sales
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN 
            (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ss.s_store_sk
),
HighValueStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        ss.total_sales,
        ss.number_of_sales
    FROM 
        store s
    JOIN 
        StoreSalesSummary ss ON s.s_store_sk = ss.s_store_sk
    WHERE 
        ss.total_sales > (SELECT AVG(total_sales) FROM StoreSalesSummary)
)
SELECT 
    cs.c_customer_sk,
    cs.avg_purchase_estimate,
    hvs.s_store_name,
    hvs.total_sales,
    hvs.number_of_sales,
    RANK() OVER (PARTITION BY hvs.s_store_sk ORDER BY cs.avg_purchase_estimate DESC) AS rank_by_purchase_estimate
FROM 
    CustomerStats cs
JOIN 
    HighValueStores hvs ON cs.c_customer_sk IN (
        SELECT DISTINCT ws.ws_bill_customer_sk 
        FROM web_sales ws 
        WHERE ws.ws_ship_date_sk IS NOT NULL
    )
ORDER BY 
    hvs.total_sales DESC, 
    cs.avg_purchase_estimate DESC;
