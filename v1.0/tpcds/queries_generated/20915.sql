
WITH relevant_sales AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        ss.ext_sales_price,
        ss.ext_tax,
        ss.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY ss.sold_date_sk DESC) AS rn
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
sales_summary AS (
    SELECT 
        item_sk,
        SUM(ext_sales_price) AS total_sales,
        COUNT(DISTINCT sold_date_sk) AS sales_days
    FROM 
        relevant_sales
    WHERE 
        rn <= 3  -- only consider last 3 sales for each item
    GROUP BY 
        item_sk
),
customer_info AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cd.gender,
        cd.marital_status,
        cd.purchase_estimate,
        cd.credit_rating,
        d.d_date AS purchase_date
    FROM 
        customer c
    JOIN customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    LEFT JOIN store_sales ss ON c.customer_sk = ss.customer_sk
    JOIN date_dim d ON d.d_date_sk = ss.sold_date_sk
),
top_customers AS (
    SELECT 
        ci.first_name,
        ci.last_name,
        ci.purchase_estimate,
        RANK() OVER (ORDER BY SUM(rs.total_sales) DESC) AS customer_rank
    FROM 
        customer_info ci
    JOIN sales_summary rs ON ci.customer_sk = rs.item_sk
    GROUP BY 
        ci.first_name, ci.last_name, ci.purchase_estimate
    HAVING 
        SUM(rs.total_sales) IS NOT NULL
)
SELECT 
    t.first_name,
    t.last_name,
    COALESCE(t.purchase_estimate, 0) AS estimated_purchase,
    COUNT(DISTINCT ci.purchase_date) AS distinct_purchase_dates,
    STRING_AGG(DISTINCT ci.gender || ' - ' || ci.marital_status) AS demographics_info
FROM 
    top_customers t
LEFT JOIN 
    customer_info ci ON t.first_name = ci.first_name AND t.last_name = ci.last_name
WHERE 
    t.customer_rank <= 10
GROUP BY 
    t.first_name, t.last_name, t.purchase_estimate
ORDER BY 
    estimated_purchase DESC;
