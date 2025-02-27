
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_first_name) AS gender_rank
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_payment,
        MAX(ws_net_profit) AS max_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
final_summary AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(ss.order_count, 0) AS order_count,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(ss.total_sales, 0) = 0 THEN NULL
            WHEN COALESCE(rs.total_return_amount, 0) = 0 THEN COALESCE(ss.total_sales, 0)
            ELSE COALESCE(ss.total_sales, 0) - COALESCE(rs.total_return_amount, 0) 
        END AS net_sales
    FROM 
        ranked_customers r
    LEFT JOIN 
        sales_summary ss ON r.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN 
        returns_summary rs ON r.c_customer_sk = rs.sr_returning_customer_sk
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.total_sales,
    fs.order_count,
    fs.total_returns,
    fs.total_return_amount,
    fs.net_sales,
    CASE 
        WHEN fs.net_sales <= (SELECT AVG(net_sales) FROM final_summary) THEN 'Below Average'
        ELSE 'Above Average'
    END AS sales_performance,
    RANK() OVER (ORDER BY fs.net_sales DESC) AS sales_rank
FROM 
    final_summary fs
ORDER BY 
    fs.sales_rank;
