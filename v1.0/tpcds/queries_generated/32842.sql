
WITH RECURSIVE sales_summary AS (
    SELECT 
        s_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(SUM(ss.ss_net_profit), 0) as total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
return_summary AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_returns,
        COUNT(*) AS total_return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name, 
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        COALESCE(rs.total_returns, 0) AS total_returns,
        cs.total_profit,
        sales.total_sales
    FROM 
        customer_summary cs
    LEFT JOIN 
        return_summary rs ON cs.c_customer_sk = rs.sr_customer_sk
    LEFT JOIN 
        sales_summary sales ON cs.c_customer_sk = sales.s_store_sk
)
SELECT 
    s_store_name AS Store_Name,
    c_first_name AS First_Name,
    c_last_name AS Last_Name,
    cd_gender AS Gender,
    cd_marital_status AS Marital_Status,
    total_sales AS Total_Sales,
    total_profit AS Total_Profit,
    total_returns AS Total_Returns,
    CASE
        WHEN total_sales > 100000 THEN 'High Roller'
        WHEN total_sales BETWEEN 50000 AND 100000 THEN 'Mid Tier'
        ELSE 'Budget Buyer'
    END AS Buyer_Category
FROM 
    summary 
JOIN 
    store s ON summary.s_store_sk = s.s_store_sk
WHERE 
    total_profit > 0 
ORDER BY 
    total_sales DESC
LIMIT 100;
