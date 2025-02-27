
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ws_sold_date_sk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk

    UNION ALL

    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        cs_sold_date_sk
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk, cs_sold_date_sk
),

customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_store_visits
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_preferred_cust_flag, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),

sales_summary AS (
    SELECT 
        d.d_date AS sale_date,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_sales) AS total_sales,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        sales_data sd
    JOIN 
        date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        customer_info c ON c.total_store_visits > 1
    GROUP BY 
        d.d_date
)

SELECT 
    ss.sale_date,
    ss.total_quantity,
    ss.total_sales,
    ss.unique_customers,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        ELSE CASE 
            WHEN ss.total_sales > 100000 THEN 'High Sales'
            ELSE 'Normal Sales'
        END 
    END AS sales_performance
FROM 
    sales_summary ss
WHERE 
    ss.unique_customers > 10
ORDER BY 
    ss.total_sales DESC;

