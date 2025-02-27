
WITH RECURSIVE date_range AS (
    SELECT MIN(d_date_sk) AS start_date, MAX(d_date_sk) AS end_date
    FROM date_dim
),
sales_summary AS (
    SELECT 
        d.d_year AS year,
        d.d_month AS month,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_net_paid) AS average_sale,
        SUM(CASE WHEN ss.ss_net_profit > 0 THEN 1 ELSE 0 END) AS profitable_sales
    FROM date_dim d
    JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY d.d_year, d.d_month
),
customer_summary AS (
    SELECT 
        cd.cd_gender, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count, 
        SUM(cd.cd_purchase_estimate) AS total_estimate,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    sr.sm_ship_mode_id,
    sr.sm_type,
    s.year,
    s.month,
    cs.customer_count,
    cs.total_estimate,
    ss.total_sales,
    ss.total_profit,
    ss.average_sale,
    ss.profitable_sales
FROM sales_summary ss
JOIN ship_mode sr ON sr.sm_ship_mode_sk = (SELECT 
                                               sm_ship_mode_sk 
                                           FROM store_sales 
                                           WHERE ss_ticket_number = (SELECT MAX(ss_ticket_number) FROM store_sales)
                                           LIMIT 1)
CROSS JOIN customer_summary cs
JOIN date_range dr ON dr.start_date <= ss.year AND dr.end_date >= ss.year
WHERE ss.total_sales > 0
ORDER BY s.year DESC, s.month DESC;
