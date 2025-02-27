
WITH RECURSIVE income_breakdown AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        0 AS depth
    FROM 
        income_band
    WHERE 
        ib_income_band_sk = 1
    UNION ALL
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        depth + 1
    FROM 
        income_band ib
    JOIN income_breakdown ibd ON ibd.ib_income_band_sk + 1 = ib.ib_income_band_sk
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk
),
avg_sales AS (
    SELECT 
        AVG(total_sales) AS average_sales 
    FROM
        sales_summary
)
SELECT 
    ca.ca_city, 
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(ss.total_sales) AS total_sales,
    AVG(ss.total_sales) AS avg_sales_per_customer,
    (CASE 
        WHEN AVG(ss.total_sales) IS NULL THEN 'No Sales'
        WHEN AVG(ss.total_sales) > (SELECT average_sales FROM avg_sales) THEN 'Above Average'
        ELSE 'Below Average'
    END) AS sales_performance,
    (SELECT 
        STRING_AGG(CONCAT('Income Band ', ib.ib_income_band_sk, ': ', 
        ib.ib_lower_bound, ' - ', ib.ib_upper_bound), ', ')
     FROM 
        income_breakdown ib
     WHERE 
        EXISTS (SELECT 1 FROM household_demographics hd WHERE hd.hd_income_band_sk = ib.ib_income_band_sk)
    ) AS income_bands
FROM 
    customer_address ca
LEFT OUTER JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.c_customer_sk
GROUP BY 
    ca.ca_city
ORDER BY 
    customer_count DESC;
