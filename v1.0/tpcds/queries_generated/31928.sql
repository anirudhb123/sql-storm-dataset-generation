
WITH RECURSIVE cte_category_sales AS (
    SELECT
        i.category AS category,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.category
    UNION ALL
    SELECT
        i.category AS category,
        SUM(cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(cs_ext_sales_price) DESC) AS rank
    FROM
        item i
    JOIN
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY
        i.category
),
target_dates AS (
    SELECT 
        d.d_date AS sales_date,
        d.d_year,
        d.d_month,
        d.d_weekend
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2023 AND (d.d_weekend = 'Y' OR d.d_holiday = 'Y')
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.marital_status = 'M' THEN 'Married'
            WHEN cd.marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        COUNT(cd.hd_demo_sk) AS total_dependents
    FROM 
        customer c
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, marital_status
)
SELECT
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    c.c_email_address,
    cs.total_sales,
    cs.marital_status,
    COALESCE(ad.total_sales, 0) AS adjustment_sales
FROM 
    customer c
JOIN 
    customer_stats cs ON c.c_customer_sk = cs.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN (
    SELECT 
        ca.ca_city,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE 
        EXISTS (SELECT 1 FROM target_dates td WHERE td.sales_date = ws.ws_sold_date_sk)
    GROUP BY 
        ca.ca_city
) ad ON ca.ca_city = ad.ca_city
LEFT JOIN (
    SELECT 
        i.i_category,
        SUM(sp.ws_ext_sales_price) AS seasonal_sales
    FROM 
        web_sales sp
    JOIN 
        item i ON sp.ws_item_sk = i.i_item_sk
    WHERE 
        DATE_PART('month', sp.ws_sold_date_sk) IN (6, 7, 8) -- Summer months
    GROUP BY 
        i.i_category
) summer_sales ON summer_sales.i_category = cs.total_sales
WHERE 
    cs.total_sales > (SELECT AVG(total_sales) FROM cte_category_sales)
ORDER BY 
    c.c_first_name, c.c_last_name;
