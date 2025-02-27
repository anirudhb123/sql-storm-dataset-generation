
WITH RECURSIVE repeated_customer AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year > 1975
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS sales_count,
        AVG(ss.ss_list_price) AS avg_list_price
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
sales_details AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cc.cc_name,
        cs.total_sales,
        cs.sales_count,
        cs.avg_list_price,
        CASE 
            WHEN cs.total_sales IS NULL THEN 'No Sales'
            ELSE 'Active'
        END AS sales_status
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    LEFT JOIN 
        call_center cc ON c.c_customer_sk = cc.cc_call_center_sk 
),
final_output AS (
    SELECT 
        rc.c_first_name,
        rc.c_last_name,
        rc.c_email_address,
        sd.cc_name,
        sd.total_sales,
        sd.sales_count,
        RANK() OVER (PARTITION BY rc.c_customer_sk ORDER BY sd.total_sales DESC) AS rank_sales,
        NULLIF(sd.avg_list_price, 0) AS adjusted_avg_price
    FROM 
        repeated_customer rc
    LEFT JOIN 
        sales_details sd ON rc.c_customer_sk = sd.c_customer_sk
    WHERE 
        rc.rn = 1
)
SELECT 
    fo.c_first_name,
    fo.c_last_name,
    fo.c_email_address,
    fo.cc_name,
    COALESCE(fo.total_sales, 0) AS total_sales,
    COALESCE(fo.sales_count, 0) AS sales_count,
    CASE 
        WHEN fo.rank_sales IS NULL THEN 'No Rank'
        ELSE CAST(fo.rank_sales AS CHAR)
    END AS rank_sales,
    CASE 
        WHEN fo.adjusted_avg_price IS NULL THEN 'N/A'
        ELSE ROUND(fo.adjusted_avg_price, 2)
    END AS avg_sales_price
FROM 
    final_output fo
ORDER BY 
    fo.total_sales DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
