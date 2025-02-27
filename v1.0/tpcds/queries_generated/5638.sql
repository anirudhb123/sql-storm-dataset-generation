
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
SalesByMonth AS (
    SELECT 
        EXTRACT(YEAR FROM d.d_date) AS sales_year,
        EXTRACT(MONTH FROM d.d_date) AS sales_month,
        SUM(cs.total_net_profit) AS monthly_net_profit,
        AVG(cs.avg_sales_price) AS average_sales_price,
        SUM(cs.order_count) AS total_orders
    FROM 
        date_dim d
    JOIN 
        CustomerSales cs ON d.d_date_sk = ws.ws_sold_date_sk 
    GROUP BY 
        sales_year, sales_month
)
SELECT 
    sales_year, 
    sales_month, 
    monthly_net_profit, 
    average_sales_price,
    total_orders,
    RANK() OVER (ORDER BY monthly_net_profit DESC) AS profit_rank
FROM 
    SalesByMonth
ORDER BY 
    sales_year, sales_month;
