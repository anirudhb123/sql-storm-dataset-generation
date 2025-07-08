
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_sk
),
SalesTrend AS (
    SELECT 
        d.d_year,
        SUM(cs.total_net_profit) AS yearly_net_profit,
        AVG(cs.avg_sales_price) AS avg_sales_price_per_year,
        COUNT(cs.total_orders) AS total_orders_per_year
    FROM 
        CustomerSales cs
    JOIN 
        date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = cs.c_customer_sk)
    GROUP BY 
        d.d_year
),
TopYear AS (
    SELECT 
        d_year, 
        yearly_net_profit,
        RANK() OVER (ORDER BY yearly_net_profit DESC) AS profit_rank
    FROM 
        SalesTrend
)
SELECT 
    d.d_year,
    d.yearly_net_profit,
    d.avg_sales_price_per_year,
    d.total_orders_per_year
FROM 
    SalesTrend d
WHERE 
    d.d_year = (SELECT d_year FROM TopYear WHERE profit_rank = 1);
