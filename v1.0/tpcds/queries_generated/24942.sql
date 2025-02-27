
WITH sales_data AS (
    SELECT 
        w.warehouse_name,
        ss.sold_date_sk,
        SUM(ss.sales_price) AS total_sales,
        COUNT(DISTINCT ss.customer_sk) AS unique_customers,
        DENSE_RANK() OVER (PARTITION BY w.warehouse_name ORDER BY SUM(ss.sales_price) DESC) AS sales_rank
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.store_sk = w.warehouse_sk
    WHERE 
        ss.sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        w.warehouse_name, ss.sold_date_sk
), 
customer_data AS (
    SELECT 
        c.customer_id,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        SUM(COALESCE(ws.net_profit, 0)) AS total_profit,
        COUNT(DISTINCT ws.order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cd.gender ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    LEFT JOIN 
        web_sales ws ON c.customer_sk = ws.bill_customer_sk
    GROUP BY 
        c.customer_id, cd.gender, cd.marital_status, cd.education_status
)
SELECT 
    s.warehouse_name,
    s.sold_date_sk,
    c.customer_id,
    c.gender,
    s.total_sales,
    c.total_profit
FROM 
    sales_data s
FULL OUTER JOIN 
    customer_data c ON s.sales_rank = c.profit_rank
WHERE 
    (c.total_profit IS NOT NULL OR s.total_sales IS NOT NULL)
    AND (s.total_sales > 1000 OR c.order_count > 5)
ORDER BY 
    s.warehouse_name, c.gender, s.sold_date_sk;
