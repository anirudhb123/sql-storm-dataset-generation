
WITH sales_summary AS (
    SELECT 
        s.ss_sold_date_sk,
        SUM(s.ss_sales_price) AS total_sales,
        COUNT(DISTINCT s.ss_ticket_number) AS total_transactions,
        SUM(s.ss_quantity) AS total_units_sold,
        c.c_birth_year,
        cd.cd_gender,
        ca.ca_city
    FROM store_sales s
    JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE s.ss_sold_date_sk BETWEEN 2451545 AND 2451545 + 30 -- Last 30 days of sales
    GROUP BY s.ss_sold_date_sk, c.c_birth_year, cd.cd_gender, ca.ca_city
),
gender_distribution AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers
    FROM date_dim dd
    JOIN store_sales ss ON dd.d_date_sk = ss.ss_sold_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE dd.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY dd.d_year, dd.d_month_seq
),
avg_sales_by_gender AS (
    SELECT 
        g.d_year,
        g.d_month_seq,
        g.female_customers,
        g.male_customers,
        (SELECT AVG(total_sales) FROM sales_summary WHERE c.c_current_cdemo_sk IS NOT NULL AND c.c_current_cdemo_sk = g.d_year AND c.c_current_cdemo_sk = 'F') AS avg_female_sales,
        (SELECT AVG(total_sales) FROM sales_summary WHERE c.c_current_cdemo_sk IS NOT NULL AND c.c_current_cdemo_sk = g.d_year AND c.c_current_cdemo_sk = 'M') AS avg_male_sales
    FROM gender_distribution g
)
SELECT 
    d.d_year,
    d.d_month_seq,
    g.female_customers,
    g.male_customers,
    g.avg_female_sales,
    g.avg_male_sales
FROM date_dim d
JOIN avg_sales_by_gender g ON d.d_year = g.d_year AND d.d_month_seq = g.d_month_seq
ORDER BY d.d_year, d.d_month_seq;
