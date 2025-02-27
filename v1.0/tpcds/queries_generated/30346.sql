
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (
            SELECT MIN(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023
        )
    GROUP BY 
        ws.web_site_sk, 
        ws.ws_order_number
),
sales_ranked AS (
    SELECT 
        sd.web_site_sk,
        sd.ws_order_number,
        sd.total_sales,
        RANK() OVER (PARTITION BY sd.web_site_sk ORDER BY sd.total_sales DESC) as sales_rank
    FROM 
        sales_data sd
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        COALESCE(cd.cd_gender, 'Unknown') AS customer_gender,
        COALESCE(hd.hd_buy_potential, 'Low') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        sales_ranked sr ON c.c_customer_sk = sr.ws_order_number
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        sr.sales_rank <= 5 OR sr.sales_rank IS NULL
),
sales_summary AS (
    SELECT 
        customer_gender,
        buy_potential,
        SUM(total_sales) AS total_sales,
        COUNT(*) AS customer_count
    FROM 
        customer_sales
    GROUP BY 
        customer_gender, 
        buy_potential
)

SELECT 
    css.customer_gender,
    css.buy_potential,
    css.total_sales,
    css.customer_count,
    CASE 
        WHEN css.total_sales IS NULL THEN 'No Sales'
        ELSE CAST(css.total_sales AS VARCHAR)
    END AS sales_info
FROM 
    sales_summary css
WHERE 
    css.total_sales > 1000
    OR css.customer_count > 10
ORDER BY 
    css.total_sales DESC
LIMIT 10;
