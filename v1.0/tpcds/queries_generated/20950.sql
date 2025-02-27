
WITH sales_summary AS (
    SELECT 
        s_store_sk,
        SUM(ss_quantity) AS total_items_sold,
        SUM(ss_net_profit) AS total_net_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 1 AND 1000
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
        cd.cd_credit_rating,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        MAX(wr_returned_date_sk) AS last_web_return_date
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' AND (cd.cd_credit_rating = 'Fair' OR cd.cd_credit_rating IS NULL)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
highest_return AS (
    SELECT 
        c.c_customer_sk,
        ROW_NUMBER() OVER (ORDER BY total_web_returns DESC) AS rn
    FROM 
        customer_summary c
    WHERE 
        total_web_returns > (SELECT AVG(total_web_returns) FROM customer_summary)
),
final_report AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cs.total_items_sold,
        cs.total_net_profit,
        CASE 
            WHEN cs.total_net_profit IS NULL THEN 'No Profit'
            WHEN cs.total_net_profit > 1000 THEN 'High Profit'
            ELSE 'Moderate Profit'
        END AS profit_category,
        CASE 
            WHEN wr.last_web_return_date IS NOT NULL THEN CONCAT('Last Return on ', wr.last_web_return_date)
            ELSE 'No Returns'
        END AS return_info
    FROM 
        sales_summary cs
    JOIN 
        highest_return hr ON cs.s_store_sk = hr.c_customer_sk
    JOIN 
        customer_summary c ON hr.c_customer_sk = c.c_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
)
SELECT 
    *
FROM 
    final_report
WHERE 
    total_net_profit IS NOT NULL
ORDER BY 
    total_net_profit DESC
LIMIT 10;
