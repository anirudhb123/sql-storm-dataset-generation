
WITH RankedSales AS (
    SELECT 
        ws.web_site_id, 
        COALESCE(ss.ss_sold_date_sk, cs.cs_sold_date_sk) AS sold_date,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    GROUP BY 
        ws.web_site_id, ss.ss_sold_date_sk, cs.cs_sold_date_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        hd.hd_income_band_sk,
        c.c_last_name, 
        c.c_first_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        ci.c_customer_id,
        ci.c_last_name,
        ci.c_first_name,
        COALESCE(rs.total_sales, 0) AS total_sales,
        ci.hd_income_band_sk
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        RankedSales rs ON ci.c_customer_id = rs.web_site_id
)
SELECT 
    ss.c_last_name,
    ss.c_first_name,
    CASE 
        WHEN ss.total_sales > 1000 THEN 'High Value'
        WHEN ss.total_sales > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    CASE 
        WHEN ss.hd_income_band_sk IS NULL THEN 'Unknown Income'
        ELSE 'Known Income Band'
    END AS income_category
FROM 
    SalesSummary ss
WHERE 
    ss.total_sales IS NOT NULL
ORDER BY 
    ss.total_sales DESC;
