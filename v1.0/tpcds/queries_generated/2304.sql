
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id, ws_sold_date_sk
),
AggregateSales AS (
    SELECT 
        web_site_id,
        SUM(total_quantity) AS aggregate_quantity,
        SUM(total_profit) AS aggregate_profit,
        COUNT(DISTINCT total_orders) AS total_unique_orders
    FROM 
        SalesData
    GROUP BY 
        web_site_id
),
CustomerAnalysis AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        ca.net_profit,
        RANK() OVER (ORDER BY ca.net_profit DESC) AS rank
    FROM 
        CustomerAnalysis ca
    JOIN 
        customer c ON c.c_customer_id = ca.c_customer_id
    WHERE 
        ca.order_count > 5
)
SELECT 
    sa.web_site_id,
    sa.aggregate_quantity,
    sa.aggregate_profit,
    COALESCE(tc.rank, 0) AS top_customer_rank,
    COUNT(*) FILTER (WHERE tc.rank <= 10) AS top_customers_count
FROM 
    AggregateSales sa
LEFT JOIN 
    TopCustomers tc ON sa.web_site_id = tc.c_customer_id
GROUP BY 
    sa.web_site_id, sa.aggregate_quantity, sa.aggregate_profit
ORDER BY 
    sa.aggregate_profit DESC
LIMIT 20;
