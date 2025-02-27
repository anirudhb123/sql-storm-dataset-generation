
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
StoreSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        AVG(ss.ss_net_profit) AS avg_store_profit
    FROM 
        customer AS c
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesComparison AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.order_count,
        ss.total_store_sales,
        ss.store_order_count,
        (cs.total_web_sales + COALESCE(ss.total_store_sales, 0)) AS total_sales,
        (cs.avg_profit + COALESCE(ss.avg_store_profit, 0)) AS combined_avg_profit
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_id = ss.c_customer_id
),
RankedSales AS (
    SELECT 
        customer_id,
        total_sales,
        combined_avg_profit,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesComparison
)

SELECT 
    r.customer_id,
    r.total_sales,
    r.combined_avg_profit,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top 10 Customer'
        WHEN r.sales_rank <= 50 THEN 'Top 50 Customer'
        ELSE 'Other'
    END AS customer_category
FROM 
    RankedSales r
WHERE 
    r.total_sales IS NOT NULL
ORDER BY 
    r.sales_rank;
