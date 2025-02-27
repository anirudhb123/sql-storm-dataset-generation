
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
demographics_aggregation AS (
    SELECT 
        cd.cd_demo_sk,
        MIN(cd.cd_purchase_estimate) AS min_purchase_estimate,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        ca.ca_state,
        SUM(cs.total_web_sales) AS total_web_sales,
        SUM(cs.total_catalog_sales) AS total_catalog_sales,
        SUM(cs.total_store_sales) AS total_store_sales,
        DECODE(cd.cd_gender, 'M', 'Male', 'F', 'Female', 'Other') AS gender,
        d.d_year
    FROM 
        customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN demographics_aggregation cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY
        ca.ca_state,
        cd.cd_demo_sk,
        cd.cd_gender,
        d.d_year
)
SELECT 
    state,
    gender,
    year,
    SUM(total_web_sales) AS total_web_sales,
    SUM(total_catalog_sales) AS total_catalog_sales,
    SUM(total_store_sales) AS total_store_sales
FROM 
    sales_summary
GROUP BY 
    state, 
    gender, 
    year
ORDER BY 
    state, 
    gender, 
    year;
