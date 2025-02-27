
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.net_paid) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_sk
),
TopWebsites AS (
    SELECT web_site_sk
    FROM RankedSales
    WHERE sales_rank <= 5
),
StoreSalesStats AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ticket_number) AS store_order_count,
        AVG(ss.sales_price) AS avg_sales_price
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.store_sk = s.s_store_sk
    WHERE 
        s.s_closed_date_sk IS NULL
    GROUP BY 
        s.s_store_sk
),
WebsiteStoreSummary AS (
    SELECT 
        t.web_site_sk,
        COALESCE(s.total_store_sales, 0) AS total_store_sales,
        COALESCE(s.store_order_count, 0) AS store_order_count
    FROM 
        TopWebsites t
    LEFT JOIN 
        StoreSalesStats s ON t.web_site_sk = s.s_store_sk
)
SELECT 
    w.web_site_id,
    w.web_name,
    w.total_store_sales,
    w.store_order_count,
    COALESCE(w.total_store_sales, 0) / NULLIF(w.store_order_count, 0) AS avg_sales_per_order
FROM 
    web_site w
JOIN 
    WebsiteStoreSummary ws ON w.web_site_sk = ws.web_site_sk
WHERE 
    w.web_gmt_offset = (SELECT MAX(web_gmt_offset) FROM web_site)
ORDER BY 
    avg_sales_per_order DESC;
