
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
Top_Customers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.order_count,
        cs.avg_profit,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        Customer_Sales cs
    JOIN 
        (SELECT c_customer_id FROM customer WHERE c_preferred_cust_flag = 'Y') AS c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > 1000
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.order_count,
    tc.avg_profit,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Other Customers'
    END AS customer_segment,
    COALESCE((
        SELECT COUNT(DISTINCT ws_item_sk)
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = tc.customer_id)
    ), 0) AS distinct_items_purchased
FROM 
    Top_Customers tc
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = tc.customer_id)
WHERE 
    cd.cd_gender = 'F'
ORDER BY 
    tc.total_sales DESC;
