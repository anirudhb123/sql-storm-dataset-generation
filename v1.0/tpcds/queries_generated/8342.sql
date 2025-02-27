
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
),
returns_summary AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(DISTINCT cr_order_number) AS return_count,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
combined_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count,
        COALESCE(rs.return_count, 0) AS return_count,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.cs_bill_customer_sk
    LEFT JOIN 
        returns_summary rs ON ci.c_customer_sk = rs.cr_returning_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    cs.total_sales,
    cs.order_count,
    cs.return_count,
    cs.total_return_amount,
    CASE 
        WHEN cs.return_count > 0 THEN (cs.total_return_amount / cs.total_sales) * 100
        ELSE 0 
    END AS return_percentage
FROM 
    combined_summary cs
JOIN 
    customer_info c ON cs.c_customer_sk = c.c_customer_sk
WHERE 
    cs.total_sales > 1000
ORDER BY 
    return_percentage DESC
LIMIT 50;
