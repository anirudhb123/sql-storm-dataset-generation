
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk, 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_net_paid) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
), 
Date_Range AS (
    SELECT 
        d_date_sk, 
        d_year, 
        d_month_seq, 
        d_week_seq
    FROM 
        date_dim 
    WHERE 
        d_year = 2023
),
Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ds.d_year, 
    ds.d_month_seq,
    cs.c_first_name, 
    cs.c_last_name,
    CASE 
        WHEN cs.total_web_sales IS NULL AND cs.total_store_sales IS NULL THEN 'No Sales'
        ELSE COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_store_sales, 0)
    END AS total_sales,
    RANK() OVER (PARTITION BY ds.d_year, ds.d_month_seq ORDER BY
        CASE 
            WHEN cs.total_web_sales IS NULL THEN 0 
            ELSE cs.total_web_sales 
        END DESC) AS sales_rank,
    ROW_NUMBER() OVER (PARTITION BY ds.d_year, ds.d_month_seq ORDER BY 
        total_sales DESC) AS sales_rank_by_total
FROM 
    Date_Range ds
JOIN 
    Customer_Summary cs ON csTotal_Sales IS NOT NULL
WHERE 
    ds.d_month_seq IN (SELECT DISTINCT d_month_seq FROM date_dim WHERE d_year = 2023)
ORDER BY 
    total_sales DESC;
