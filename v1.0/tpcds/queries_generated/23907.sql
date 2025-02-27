
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_ship_mode_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND (c.c_birth_month, c.c_birth_day) BETWEEN (1, 1) AND (12, 31)
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk, ws_ship_mode_sk
),
SalesWithAddress AS (
    SELECT 
        r.web_site_sk,
        r.total_sales,
        COALESCE(ca.city, 'Unknown') AS city,
        COALESCE(ca.state, 'N/A') AS state,
        r.rank
    FROM 
        RankedSales r
    LEFT JOIN 
        customer_address ca ON ca.ca_address_sk = (
            SELECT 
                c_current_addr_sk 
            FROM 
                customer 
            WHERE 
                c_customer_sk = r.web_site_sk
        )
    WHERE 
        r.rank <= 5
),
FinalResults AS (
    SELECT 
        r.web_site_sk,
        r.total_sales,
        r.city,
        r.state,
        CASE 
            WHEN r.total_sales > 10000 THEN 'High' 
            WHEN r.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        SalesWithAddress r
)
SELECT 
    fr.web_site_sk,
    fr.total_sales,
    fr.city,
    fr.state,
    fr.sales_category,
    (SELECT COUNT(*) FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL) AS customer_count,
    (SELECT AVG(cs_ext_sales_price) FROM catalog_sales) AS avg_catalog_price
FROM 
    FinalResults fr
ORDER BY 
    fr.total_sales DESC, 
    fr.city ASC NULLS LAST;
