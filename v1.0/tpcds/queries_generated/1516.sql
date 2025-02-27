
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_cdemo_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk, ws_bill_cdemo_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        (SELECT 
             COUNT(*) 
         FROM 
             customer_address ca 
         WHERE 
             ca.ca_address_sk = c.c_current_addr_sk) AS address_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_income_band_sk,
        ci.address_count,
        rs.total_sales,
        rs.sales_rank,
        rs.order_count
    FROM 
        customer_info ci
    LEFT JOIN 
        ranked_sales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    s.sales_rank,
    CASE 
        WHEN s.cd_gender = 'F' THEN 'Female'
        WHEN s.cd_gender = 'M' THEN 'Male'
        ELSE 'Other'
    END AS gender,
    s.order_count,
    CASE 
        WHEN s.address_count IS NULL THEN 'No Address'
        ELSE 'Address Exists'
    END AS address_status
FROM 
    sales_summary s
WHERE 
    s.total_sales > (SELECT AVG(total_sales) 
                      FROM ranked_sales 
                      WHERE sales_rank <= 5)
ORDER BY 
    s.total_sales DESC
LIMIT 100;
