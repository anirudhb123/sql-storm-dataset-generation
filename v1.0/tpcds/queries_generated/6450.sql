
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.order_count,
        cs.avg_net_profit,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.order_count > 10
),
PromotionAnalysis AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        EXISTS (SELECT 1 FROM TopCustomers tc WHERE tc.customer_id = ws.ws_bill_customer_sk)
    GROUP BY 
        p.p_promo_name
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.order_count,
    tc.avg_net_profit,
    pa.p_promo_name,
    pa.total_revenue,
    pa.order_count AS promo_order_count,
    pa.avg_net_profit AS promo_avg_net_profit
FROM 
    TopCustomers tc
LEFT JOIN 
    PromotionAnalysis pa ON tc.sales_rank = pa.order_count
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
