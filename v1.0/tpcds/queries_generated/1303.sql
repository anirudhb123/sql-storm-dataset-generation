
WITH SalesData AS (
    SELECT
        dt.d_date AS sales_date,
        ws.ws_sales_price,
        cs.cs_sales_price,
        ss.ss_sales_price,
        COALESCE(ws.ws_sales_price, cs.cs_sales_price, ss.ss_sales_price) AS effective_sales_price,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        SUM(COALESCE(ws.ws_sales_price, 0) + COALESCE(cs.cs_sales_price, 0) + COALESCE(ss.ss_sales_price, 0)) AS total_sales
    FROM
        date_dim dt
    LEFT JOIN web_sales ws ON dt.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON dt.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON dt.d_date_sk = ss.ss_sold_date_sk
    JOIN customer c ON COALESCE(ws.ws_bill_customer_sk, cs.cs_bill_customer_sk, ss.ss_customer_sk) = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        dt.d_year = 2023 AND (cd.cd_gender = 'F' OR cd.cd_income_band_sk IS NOT NULL)
    GROUP BY
        dt.d_date, ws.ws_sales_price, cs.cs_sales_price, ss.ss_sales_price, c.c_customer_id, cd.cd_gender, cd.cd_income_band_sk
),
RankedSales AS (
    SELECT 
        sales_date,
        effective_sales_price,
        c_customer_id,
        cd_gender,
        total_sales,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
)
SELECT
    sales_date,
    c_customer_id,
    cd_gender,
    total_sales,
    CASE 
        WHEN sales_rank = 1 THEN 'Top Performer'
        WHEN sales_rank <= 5 THEN 'Top 5 Performer'
        ELSE 'Other'
    END AS performance_category
FROM RankedSales
WHERE effective_sales_price > 20.00
ORDER BY sales_date, total_sales DESC;
