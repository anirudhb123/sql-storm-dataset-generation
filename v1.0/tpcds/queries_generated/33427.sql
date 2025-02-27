
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    UNION ALL
    SELECT 
        ss_sold_date_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk < (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        ss_sold_date_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        (SELECT COUNT(*) FROM customer_demographics WHERE cd_demo_sk = c.c_current_cdemo_sk 
         AND cd_marital_status = 'M') AS married_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
return_summary AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned  
    FROM 
        web_returns wr 
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    dt.d_date AS sales_date,
    COALESCE(ss.total_quantity, 0) AS total_web_sales,
    COALESCE(st.total_sales, 0) AS total_store_sales,
    ci.c_first_name || ' ' || ci.c_last_name AS customer_name,
    ci.cd_gender AS gender,
    ci.married_count,
    CASE 
        WHEN ci.cd_income_band_sk IS NULL THEN 'Unknown' 
        ELSE (SELECT ib_upper_bound FROM income_band WHERE ib_income_band_sk = ci.cd_income_band_sk)
    END AS income_band,
    COALESCE(rs.total_returned, 0) AS total_returns
FROM 
    date_dim dt
LEFT JOIN 
    sales_summary ss ON dt.d_date_sk = ss.ws_sold_date_sk
LEFT JOIN 
    store_sales st ON dt.d_date_sk = st.ss_sold_date_sk
LEFT JOIN 
    customer_info ci ON ci.c_customer_sk = (SELECT MIN(ws_bill_customer_sk) FROM web_sales WHERE ws_sold_date_sk = dt.d_date_sk)
LEFT JOIN 
    return_summary rs ON ss.ws_sold_date_sk = rs.wr_item_sk
WHERE 
    dt.d_year = 2023
ORDER BY 
    dt.d_date;
