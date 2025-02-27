
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
IncomeDemographics AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_store_sales,
    CASE
        WHEN cs.total_web_sales > cs.total_catalog_sales AND cs.total_web_sales > cs.total_store_sales THEN 'Web Sales Dominant'
        WHEN cs.total_catalog_sales > cs.total_web_sales AND cs.total_catalog_sales > cs.total_store_sales THEN 'Catalog Sales Dominant'
        ELSE 'Store Sales Dominant'
    END AS dominant_sales_type,
    COALESCE(id.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(id.ib_upper_bound, 0) AS income_upper_bound,
    (SELECT COUNT(DISTINCT ws_order_number) 
     FROM web_sales
     WHERE ws_bill_customer_sk = cs.c_customer_sk 
       AND ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)) AS this_year_web_order_count,
    ROW_NUMBER() OVER (ORDER BY cs.total_web_sales DESC) AS web_sales_rank
FROM 
    CustomerSales cs
LEFT JOIN 
    IncomeDemographics id ON cs.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_cdemo_sk = id.hd_demo_sk LIMIT 1)
WHERE 
    (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) > 1000
ORDER BY 
    cs.total_web_sales DESC, cs.total_catalog_sales DESC;
