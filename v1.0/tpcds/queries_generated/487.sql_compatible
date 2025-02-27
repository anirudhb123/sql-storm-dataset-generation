
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_id
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cp.total_spent,
        RANK() OVER (ORDER BY cp.total_spent DESC) AS spending_rank
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_customer_id = c.c_customer_id
    WHERE 
        cp.order_count > 5
)
SELECT 
    ss.web_site_id,
    ss.total_sales,
    ss.total_orders,
    ss.average_profit,
    tc.c_customer_id,
    tc.total_spent
FROM 
    SalesSummary ss
LEFT JOIN 
    TopCustomers tc ON ss.total_sales > 10000
ORDER BY 
    ss.total_sales DESC, 
    tc.total_spent DESC;
