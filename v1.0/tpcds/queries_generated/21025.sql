
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 1000 
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_acct_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS cust_rank
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 50
),
sales_rank AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_revenue,
        coalesce(ct.c_first_name || ' ' || ct.c_last_name, 'Unknown Customer') AS customer_name
    FROM 
        sales_data sd
    LEFT JOIN 
        customer_info ct ON sd.rank = ct.cust_rank
    WHERE 
        sd.total_sales > (SELECT AVG(total_sales) FROM sales_data)
)
SELECT 
    wr.wr_item_sk,
    SUM(wr.wr_return_quantity) AS total_returns,
    (sr.total_revenue - COALESCE(sr.total_revenue - SUM(wr.wr_return_amt), 0)) AS net_revenue,
    CASE 
        WHEN r.r_reason_desc IS NULL THEN 'No Reason'
        ELSE r.r_reason_desc
    END AS return_reason,
    COUNT(DISTINCT sr.customer_name) AS unique_customers
FROM 
    web_returns wr
FULL OUTER JOIN 
    sales_rank sr ON wr.wr_item_sk = sr.ws_item_sk
LEFT JOIN 
    reason r ON wr.wr_reason_sk = r.r_reason_sk
GROUP BY 
    wr.wr_item_sk, sr.total_revenue, r.r_reason_desc
HAVING 
    SUM(wr.wr_return_quantity) < (SELECT AVG(sum_return_quantity) 
                                   FROM (SELECT SUM(wr_return_quantity) as sum_return_quantity 
                                         FROM web_returns 
                                         GROUP BY wr_item_sk) AS avg_returns)
ORDER BY 
    net_revenue DESC;
