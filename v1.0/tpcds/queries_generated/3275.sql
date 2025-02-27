
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_order_value
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY 
        ws_bill_customer_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.total_sales > 1000
),
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.total_sales) AS demographic_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
top_reasons AS (
    SELECT 
        r.r_reason_desc,
        COUNT(*) AS return_count
    FROM 
        store_returns sr
    JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY 
        r.r_reason_desc
    ORDER BY 
        return_count DESC
    LIMIT 5
)
SELECT 
    hc.c_first_name,
    hc.c_last_name,
    hc.total_sales,
    hc.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    tr.return_count
FROM 
    high_value_customers hc
LEFT JOIN 
    customer_demographics cd ON hc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    top_reasons tr ON tr.return_count > 10
WHERE 
    hc.sales_rank <= 10
ORDER BY 
    hc.total_sales DESC;
