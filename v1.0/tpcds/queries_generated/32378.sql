
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim) 
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        ss.ws_item_sk, 
        ss.total_sales, 
        ss.order_count,
        i.i_item_desc,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        ss.rank <= 100
),
customer_ranking AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS orders_placed,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(ws.ws_order_number) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
final_output AS (
    SELECT 
        ts.sales_rank,
        ts.total_sales,
        ts.order_count,
        cr.orders_placed,
        CONCAT(cr.c_first_name, ' ', cr.c_last_name) AS full_name,
        cr.gender_rank,
        COALESCE(cd.ib_income_band_sk, 'Unspecified') AS income_band
    FROM 
        top_sales ts
    LEFT JOIN 
        customer_ranking cr ON ts.ws_item_sk = cr.c_customer_sk 
    LEFT JOIN 
        household_demographics hd ON cr.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band cd ON hd.hd_income_band_sk = cd.ib_income_band_sk
)
SELECT 
    f.sales_rank,
    f.total_sales,
    f.order_count,
    f.full_name,
    f.gender_rank,
    f.income_band
FROM 
    final_output f
WHERE 
    f.total_sales > (SELECT AVG(total_sales) FROM top_sales) 
ORDER BY 
    f.sales_rank
FETCH FIRST 50 ROWS ONLY;
