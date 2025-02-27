
WITH ranked_sales AS (
    SELECT
        ss.sold_date_sk,
        ss.item_sk,
        ss.store_sk,
        ss_ticket_number,
        ss_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY ss_net_paid DESC) AS rnk
    FROM
        store_sales ss
    WHERE
        ss.sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq <= 6
        )
),
sales_summary AS (
    SELECT
        r.store_sk,
        COUNT(*) AS total_sales,
        SUM(r.ss_net_paid) AS total_revenue,
        AVG(r.ss_net_paid) AS avg_net_paid,
        COUNT(DISTINCT r.item_sk) AS unique_items_sold
    FROM
        ranked_sales r
    WHERE
        r.rnk <= 5
    GROUP BY
        r.store_sk
),
customer_demographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        CASE
            WHEN cd.cd_deployed = 1 THEN 'Employed'
            ELSE 'Not Employed'
        END AS employment_status
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
detailed_summary AS (
    SELECT
        s.store_sk,
        ss.total_sales,
        ss.total_revenue,
        ss.avg_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        CASE 
            WHEN ss.avg_net_paid BETWEEN 0 AND 50 THEN 'Low'
            WHEN ss.avg_net_paid BETWEEN 51 AND 100 THEN 'Medium'
            ELSE 'High'
        END AS revenue_band
    FROM
        sales_summary ss
    LEFT JOIN customer_demographics cd ON cd.c_customer_sk = (
        SELECT TOP 1 c.c_customer_sk 
        FROM customer c 
        WHERE c.c_current_addr_sk IS NOT NULL 
        AND c.c_customer_sk BETWEEN 1 AND 10000
        ORDER BY NEWID()
    )
    LEFT JOIN household_demographics ib ON cd.cd_income_band_sk = ib.hd_income_band_sk
)
SELECT 
    ds.store_sk,
    ds.total_sales,
    ds.total_revenue,
    ds.avg_net_paid,
    ds.cd_gender,
    ds.cd_marital_status,
    COALESCE(ib.ib_lower_bound, 0) AS income_band_lower,
    COALESCE(ib.ib_upper_bound, 0) AS income_band_upper,
    ds.revenue_band
FROM 
    detailed_summary ds
JOIN income_band ib ON ds.cd_income_band_sk = ib.ib_income_band_sk
WHERE 
    ds.total_sales > 0
ORDER BY 
    ds.total_revenue DESC;
