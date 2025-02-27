
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer_address ca ON ws.bill_addr_sk = ca.ca_address_sk
    WHERE 
        ca.city IS NOT NULL
        AND ca.state IN ('CA', 'NY')
        AND ws.sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws.bill_customer_sk
),
top_customers AS (
    SELECT 
        bills.bill_customer_sk,
        bills.total_sales
    FROM 
        ranked_sales bills
    WHERE 
        bills.sales_rank <= 10
),
product_sales AS (
    SELECT 
        cs.item_sk,
        SUM(cs.net_paid) AS product_sales,
        COUNT(DISTINCT cs.bill_customer_sk) AS unique_customers
    FROM 
        catalog_sales cs
    WHERE 
        cs.sold_date_sk BETWEEN 20200101 AND 20201231
        AND cs.net_paid > 0
    GROUP BY 
        cs.item_sk
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.gender,
        cd.marital_status,
        cd.education_status,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    c.customer_id,
    ca.city,
    ca.state,
    d.gender,
    d.marital_status,
    d.education_status,
    d.ib_lower_bound,
    d.ib_upper_bound,
    COALESCE(ps.product_sales, 0) AS total_product_sales,
    COALESCE(ts.total_sales, 0) AS total_web_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics d ON c.current_cdemo_sk = d.cd_demo_sk
LEFT JOIN 
    (SELECT item_sk, SUM(product_sales) AS product_sales FROM product_sales GROUP BY item_sk) ps ON ps.item_sk = d.cd_demo_sk
LEFT JOIN 
    top_customers ts ON ts.bill_customer_sk = c.c_customer_sk
WHERE 
    (d.gender = 'M' AND d.marital_status = 'S' OR d.education_status LIKE '%Graduate%')
    AND (ca.country IS NULL OR ca.country NOT LIKE 'USA')
ORDER BY 
    total_web_sales DESC,
    c.customer_id ASC
LIMIT 50;
