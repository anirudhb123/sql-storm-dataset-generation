
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
HighIncomeDemographics AS (
    SELECT 
        hd.hd_demo_sk,
        COUNT(cd.cd_demo_sk) AS high_income_count
    FROM 
        household_demographics hd
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    WHERE 
        hd.hd_income_band_sk = (SELECT ib.ib_income_band_sk FROM income_band ib WHERE ib.ib_upper_bound > 100000)
    GROUP BY 
        hd.hd_demo_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    ss.total_store_sales,
    hid.high_income_count,
    CASE 
        WHEN cs.order_count > 10 THEN 'Frequent Shopper'
        ELSE 'Occasional Shopper'
    END AS shopper_type
FROM 
    CustomerSales cs
LEFT JOIN 
    StoreSales ss ON cs.sales_rank = ss.total_store_sales
LEFT JOIN 
    HighIncomeDemographics hid ON cs.c_customer_sk = hid.hd_demo_sk
WHERE 
    cs.total_sales IS NOT NULL
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
