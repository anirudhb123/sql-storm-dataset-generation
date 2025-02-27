
WITH RECURSIVE customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_ext_sales_price) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
income_bands AS (
    SELECT 
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 'Unknown'
            ELSE CAST(ib.ib_lower_bound AS VARCHAR) || '-' || CAST(ib.ib_upper_bound AS VARCHAR)
        END AS income_band_range
    FROM 
        income_band ib
),
sales_by_band AS (
    SELECT 
        cs.c_customer_id,
        ib.income_band_range,
        SUM(cs.total_revenue) AS revenue_by_band
    FROM 
        customer_sales cs
    LEFT JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_bands ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    GROUP BY 
        cs.c_customer_id, ib.income_band_range
),
top_sales AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        COALESCE(sb.revenue_by_band, 0) AS revenue_by_income_band
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    LEFT OUTER JOIN 
        sales_by_band sb ON c.c_customer_id = sb.c_customer_id
)
SELECT 
    t.customer_id,
    t.total_sales,
    CASE 
        WHEN t.revenue_by_income_band > 1000 THEN 'High Income'
        WHEN t.revenue_by_income_band BETWEEN 500 AND 1000 THEN 'Medium Income'
        ELSE 'Low Income'
    END AS income_category,
    (SELECT AVG(revenue_by_income_band) FROM sales_by_band) AS average_revenue,
    IFNULL(t.total_sales, 'No sales') AS sales_message,
    CASE 
        WHEN t.total_sales IS NULL THEN 'No sales recorded'
        ELSE t.total_sales || ' items sold'
    END AS sales_summary,
    ROW_NUMBER() OVER (ORDER BY t.revenue_by_income_band DESC) AS ranking
FROM 
    top_sales t
WHERE 
    (t.revenue_by_income_band > 0 OR t.total_sales IS NOT NULL)
ORDER BY 
    ranking
FETCH FIRST 10 ROWS ONLY;
