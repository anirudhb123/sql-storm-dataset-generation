
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Top_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        Customer_Sales cs
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.total_sales,
    cs.order_count,
    cs.avg_net_profit,
    COALESCE(cs.sales_rank, 'Not Ranked') AS sales_rank
FROM 
    Top_Customers cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE 
    cs.total_sales > (SELECT AVG(total_sales) FROM Customer_Sales) 
    OR cs.sales_rank <= 10
ORDER BY 
    cs.total_sales DESC 
FETCH FIRST 20 ROWS ONLY;
