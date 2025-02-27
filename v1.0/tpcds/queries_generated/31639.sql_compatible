
WITH RECURSIVE regional_sales AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_paid) AS total_net_sales,
        d_year
    FROM 
        store_sales
    JOIN 
        date_dim ON ss_sold_date_sk = d_date_sk
    GROUP BY 
        s_store_sk, d_year
), 
sales_ranking AS (
    SELECT 
        s_store_sk,
        total_net_sales,
        DENSE_RANK() OVER (PARTITION BY d_year ORDER BY total_net_sales DESC) AS sales_rank
    FROM 
        regional_sales
), 
credit_customers AS (
    SELECT 
        c_customer_sk,
        cd_credit_rating,
        cd_demo_sk
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_credit_rating IS NOT NULL
)
SELECT 
    r.s_store_sk,
    r.total_net_sales,
    r.sales_rank,
    cc.cd_credit_rating,
    (SELECT COUNT(*) 
     FROM web_sales ws 
     WHERE ws_bill_customer_sk = cc.c_customer_sk) AS web_orders_count,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss_customer_sk = cc.c_customer_sk) AS store_orders_count,
    CASE 
        WHEN cc.cd_credit_rating = 'High' THEN 'Premium Customer'
        WHEN cc.cd_credit_rating = 'Low' THEN 'Basic Customer'
        ELSE 'Standard Customer'
    END AS customer_segment
FROM 
    sales_ranking r
LEFT JOIN 
    credit_customers cc ON r.s_store_sk = cc.c_customer_sk
WHERE 
    r.sales_rank <= 10 AND 
    (NOT EXISTS (SELECT 1 
                  FROM store_returns sr 
                  WHERE sr_store_sk = r.s_store_sk AND sr_return_quantity > 0) OR 
     EXISTS (SELECT 1 
             FROM web_returns wr 
             WHERE wr_returning_customer_sk = cc.c_customer_sk 
             AND wr_return_quantity > 0))
ORDER BY 
    r.total_net_sales DESC, 
    cc.cd_credit_rating;
