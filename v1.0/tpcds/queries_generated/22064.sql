
WITH RankedSales AS (
    SELECT 
        ss_store_sk, 
        ss_item_sk, 
        ss_sales_price, 
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY ss_sales_price DESC) AS sales_rank
    FROM 
        store_sales
),
SalesSummary AS (
    SELECT 
        ss_store_sk, 
        COUNT(DISTINCT ss_item_sk) AS unique_items_sold,
        SUM(ss_sales_price) AS total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
    GROUP BY 
        ss_store_sk
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.marital_status IS NULL THEN 'Unknown'
            ELSE cd.marital_status 
        END AS marital_status,
        SUM(ws.net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.marital_status
),
FilteredMetrics AS (
    SELECT 
        c.* 
    FROM 
        CustomerMetrics c
    WHERE 
        c.total_profit IS NOT NULL 
        AND c.total_profit > (
            SELECT 
                AVG(total_profit) 
            FROM 
                CustomerMetrics
        )
)
SELECT 
    f.c_customer_sk,
    f.c_first_name, 
    f.c_last_name, 
    f.marital_status,
    s.unique_items_sold,
    s.total_sales,
    CASE 
        WHEN s.total_sales IS NULL THEN 'No Sales'
        ELSE CONCAT('Sales Total: $', ROUND(s.total_sales, 2))
    END AS sales_summary
FROM 
    FilteredMetrics f
LEFT JOIN 
    SalesSummary s ON f.c_customer_sk = s.ss_store_sk
ORDER BY 
    f.c_first_name, f.c_last_name;
