
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        1 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE 
        cd.cd_marital_status = 'S' AND ch.level < 5
),
SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS orders_count,
        COUNT(DISTINCT ws_item_sk) AS distinct_items_sold
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
ReturnSummary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amount) AS total_returns,
        COUNT(wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(sr.total_returns, 0) AS total_returns,
    ss.orders_count,
    sr.return_count,
    CASE 
        WHEN ss.total_sales > 1000 THEN 'High Value'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    DENSE_RANK() OVER (ORDER BY COALESCE(ss.total_sales, 0) DESC) AS sales_rank
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    SalesSummary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    ReturnSummary sr ON ch.c_customer_sk = sr.wr_returning_customer_sk
WHERE 
    ch.level = 1 AND (ss.total_sales IS NOT NULL OR sr.total_returns IS NOT NULL)
ORDER BY 
    sales_rank;
