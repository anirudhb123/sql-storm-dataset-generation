
WITH SummaryStats AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459165 AND 2459565 -- Filter for a specific date range
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_net_profit,
        total_orders,
        avg_sales_price,
        unique_web_pages,
        gender_rank
    FROM 
        SummaryStats
    WHERE 
        gender_rank <= 10 -- Top 10 customers by gender
)
SELECT 
    tc.c_customer_id,
    tc.total_net_profit,
    tc.total_orders,
    tc.avg_sales_price,
    tc.unique_web_pages,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ws.ws_ship_mode_sk) AS unique_shipping_modes
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_id, tc.total_net_profit, tc.total_orders, 
    tc.avg_sales_price, tc.unique_web_pages, cd.cd_gender, 
    cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    tc.total_net_profit DESC
LIMIT 50; -- Limit the results to top 50 records
