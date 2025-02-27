
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2452057 AND 2452101
    GROUP BY 
        ws_item_sk, 
        ws_order_number
), rank_sales AS (
    SELECT 
        sd.ws_item_sk, 
        sd.ws_order_number, 
        sd.total_quantity, 
        sd.total_sales, 
        sd.rank,
        COALESCE(NULLIF(sd.total_sales, 0) / NULLIF(LAG(sd.total_sales) OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.rank), 0), 0), 0) AS sales_growth
    FROM 
        sales_data sd
    WHERE 
        sd.rank <= 10
), customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_net_paid
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y' 
        AND ws.ws_ship_date_sk IS NOT NULL 
        AND (c.c_birth_year IS NOT NULL OR c.c_birth_day > 0) 
    GROUP BY 
        c.c_customer_sk
), top_customers AS (
    SELECT 
        cu.c_customer_sk, 
        cu.order_count, 
        cu.avg_net_paid,
        ROW_NUMBER() OVER (ORDER BY cu.order_count DESC, cu.avg_net_paid DESC) AS customer_rank
    FROM 
        customer_summary cu
)
SELECT 
    r.ws_item_sk, 
    r.ws_order_number, 
    r.total_quantity,
    r.total_sales,
    r.sales_growth,
    tc.c_customer_sk,
    tc.order_count,
    tc.avg_net_paid
FROM 
    rank_sales r
LEFT JOIN 
    top_customers tc ON r.ws_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_order_number = r.ws_order_number)
WHERE 
    r.sales_growth > 1
ORDER BY 
    r.total_sales DESC, 
    tc.avg_net_paid ASC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
