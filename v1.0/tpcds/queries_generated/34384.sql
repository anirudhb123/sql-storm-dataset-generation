
WITH RECURSIVE DateRange AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date >= '2023-01-01'
    UNION ALL
    SELECT d.d_date_sk, d.d_date
    FROM date_dim d
    JOIN DateRange dr ON d.d_date_sk = dr.d_date_sk + 1
),
IncomeDistribution AS (
    SELECT hd.hd_income_band_sk, COUNT(*) AS customer_count
    FROM household_demographics hd
    GROUP BY hd.hd_income_band_sk
),
SalesData AS (
    SELECT 
        COALESCE(ws.ws_ship_date_sk, ss.ss_sold_date_sk, cs.cs_sold_date_sk) AS sold_date,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        SUM(ws.ws_sales_price) AS web_sales_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        SUM(ss.ss_sales_price) AS store_sales_amount,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        SUM(cs.cs_sales_price) AS catalog_sales_amount
    FROM web_sales ws
    FULL OUTER JOIN store_sales ss ON ws.ws_ship_date_sk = ss.ss_sold_date_sk
    FULL OUTER JOIN catalog_sales cs ON ws.ws_ship_date_sk = cs.cs_sold_date_sk OR ss.ss_sold_date_sk = cs.cs_sold_date_sk
    GROUP BY COALESCE(ws.ws_ship_date_sk, ss.ss_sold_date_sk, cs.cs_sold_date_sk)
),
AggregatedSales AS (
    SELECT 
        dr.d_date,
        COALESCE(sd.web_sales_count, 0) AS web_sales,
        COALESCE(sd.store_sales_count, 0) AS store_sales,
        COALESCE(sd.catalog_sales_count, 0) AS catalog_sales,
        (COALESCE(sd.web_sales_amount, 0) + COALESCE(sd.store_sales_amount, 0) + COALESCE(sd.catalog_sales_amount, 0)) AS total_sales
    FROM DateRange dr
    LEFT JOIN SalesData sd ON dr.d_date_sk = sd.sold_date
),
CustomerSummary AS (
    SELECT 
        cd.cd_gender,
        SUM(ad.total_sales) AS total_sales_by_gender,
        AVG(hd.hd_dep_count) AS avg_dep_count,
        MAX(hd.hd_vehicle_count) AS max_vehicle_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN AggregatedSales ad ON ad.d_date = c.c_first_sales_date_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY cd.cd_gender
)
SELECT cs.cd_gender, cs.total_sales_by_gender, cs.avg_dep_count, cs.max_vehicle_count,
       CASE 
           WHEN cs.total_sales_by_gender > (SELECT AVG(total_sales_by_gender) FROM CustomerSummary) THEN 'Above Average'
           ELSE 'Below Average'
       END AS sales_category
FROM CustomerSummary cs
ORDER BY cs.total_sales_by_gender DESC;
