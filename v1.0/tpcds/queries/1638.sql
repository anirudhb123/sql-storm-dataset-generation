
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_web_quantity,
        SUM(COALESCE(cs.cs_quantity, 0)) AS total_catalog_quantity,
        SUM(COALESCE(ss.ss_quantity, 0)) AS total_store_quantity
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
income_distribution AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(*) AS frequency
    FROM 
        household_demographics h
    GROUP BY 
        h.hd_income_band_sk
),
ranked_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_quantity,
        cs.total_catalog_quantity,
        cs.total_store_quantity,
        RANK() OVER (ORDER BY (cs.total_web_quantity + cs.total_catalog_quantity + cs.total_store_quantity) DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.total_web_quantity,
    r.total_catalog_quantity,
    r.total_store_quantity,
    id.frequency,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS sales_category
FROM 
    ranked_sales r
LEFT JOIN 
    income_distribution id ON id.hd_income_band_sk = (
        SELECT 
            hd.hd_income_band_sk 
        FROM 
            household_demographics hd 
        WHERE 
            hd.hd_demo_sk = r.c_customer_sk
    )
WHERE 
    (r.total_web_quantity > 10 OR r.total_catalog_quantity > 5)
ORDER BY 
    r.sales_rank;
