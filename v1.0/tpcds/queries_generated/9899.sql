
WITH sales_summary AS (
    SELECT 
        s_store_sk,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_net_profit) AS avg_net_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s_store_sk
), 
customer_details AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws_ext_sales_price) AS total_web_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), 
customer_sales_rank AS (
    SELECT 
        c.c_customer_sk,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.total_web_sales,
        DENSE_RANK() OVER (ORDER BY c.total_web_sales DESC) AS sales_rank
    FROM 
        customer_details c
)
SELECT 
    ss.s_store_sk,
    ss.total_sales,
    ss.total_quantity,
    ss.avg_net_profit,
    csr.cd_gender,
    csr.cd_marital_status,
    csr.cd_education_status,
    csr.total_web_sales,
    csr.sales_rank
FROM 
    sales_summary ss
JOIN 
    customer_sales_rank csr ON csr.sales_rank <= 10
ORDER BY 
    ss.total_sales DESC, csr.total_web_sales DESC;
