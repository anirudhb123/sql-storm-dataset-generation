
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.order_number,
        ws.ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ext_sales_price DESC) AS rnk,
        cd.gender,
        sd.s_store_name,
        ws.quantity,
        ws_sold_date_sk,
        cs.campaign_id,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status
    FROM web_sales ws
    LEFT JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON ws.promo_sk = p.p_promo_sk
    LEFT JOIN catalog_sales cs ON ws.order_number = cs.order_number AND ws.web_site_sk = cs.bill_customer_sk
    LEFT JOIN store s ON ws.ship_addr_sk = s.s_addr_sk
    WHERE ws.sold_date_sk >= 2450000
      AND (ws.ext_sales_price IS NOT NULL OR ws.ext_sales_price > 0)
      AND (cd.gender IS NOT NULL OR c.first_name IS NOT NULL)
),
MonthlySales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(r.ext_sales_price) AS total_sales,
        COUNT(r.order_number) AS total_orders
    FROM RankedSales r
    JOIN date_dim d ON r.ws_sold_date_sk = d.d_date_sk
    WHERE r.rnk <= 5
    GROUP BY d.d_year, d.d_month_seq
),
AverageSales AS (
    SELECT 
        d_year,
        AVG(total_sales) AS avg_sales_per_month
    FROM MonthlySales
    GROUP BY d_year
)
SELECT 
    ms.d_year,
    ms.total_sales,
    ms.total_orders,
    COALESCE(ROUND(AVG(avg.avg_sales_per_month), 2), 0) AS avg_sales,
    CASE 
        WHEN ms.total_sales > 100000 THEN 'High Sales'
        WHEN ms.total_sales <= 100000 AND ms.total_sales > 50000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM MonthlySales ms
LEFT JOIN AverageSales avg ON ms.d_year = avg.d_year
LEFT JOIN customer c ON ms.ship_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag IS NOT NULL
ORDER BY ms.d_year DESC
LIMIT 10;
