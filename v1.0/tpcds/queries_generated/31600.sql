
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(sh.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT sh.ws_item_sk) AS item_count
    FROM 
        sales_hierarchy sh 
    JOIN 
        customer c ON sh.customer_sk = c.c_customer_sk
    WHERE 
        sh.rn <= 5 
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
customer_ranks AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) as sales_rank
    FROM 
        top_customers
),
filtered_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN c.c_birth_month IS NULL THEN 'Unknown'
            ELSE CONCAT(MONTHNAME(STR_TO_DATE(CONCAT(c.c_birth_month, ' 1'), '%c %e')), ' ', c.c_birth_year)
        END AS birth_info,
        r.regional_total,
        cc.cc_call_center_id 
    FROM 
        customer_ranks c
    LEFT JOIN 
        (SELECT 
            SUM(ss_ext_sales_price) AS regional_total, 
            ws_ship_customer_sk 
         FROM 
            web_sales 
         JOIN 
            store_sales ON ws_item_sk = ss_item_sk 
         GROUP BY 
            ws_ship_customer_sk) r 
    ON 
        r.ws_ship_customer_sk = c.c_customer_id
    JOIN 
        call_center cc ON c.c_customer_id = cc.cc_call_center_sk
    WHERE 
        sales_rank <= 10 
)
SELECT 
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.birth_info,
    ROUND(IFNULL(f.regional_total, 0), 2) AS regional_sales,
    COUNT(sr_return_quantity) AS total_returns,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(sr_return_tax) AS total_return_tax
FROM 
    filtered_customers f
LEFT JOIN 
    store_returns sr ON f.c_customer_id = sr.sr_customer_sk
GROUP BY 
    f.c_customer_id, f.c_first_name, f.c_last_name, f.birth_info, f.regional_total
HAVING 
    total_returns > 0 OR regional_sales > 1000
ORDER BY 
    total_sales DESC, total_returns DESC;
