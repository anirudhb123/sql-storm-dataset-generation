
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        dd.d_year = 2023 
        AND cd.cd_gender = 'F'
        AND i.i_current_price > 50.00
    GROUP BY 
        ws.web_site_id
), RankedSales AS (
    SELECT 
        web_site_id,
        total_sales,
        total_profit,
        total_orders,
        unique_customers,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    rs.web_site_id,
    rs.total_sales,
    rs.total_profit,
    rs.total_orders,
    rs.unique_customers,
    rs.sales_rank,
    CASE 
        WHEN rs.sales_rank <= 10 THEN 'Top 10'
        WHEN rs.sales_rank BETWEEN 11 AND 50 THEN 'Top 50'
        ELSE 'Others'
    END AS ranking_category
FROM 
    RankedSales rs
WHERE 
    rs.total_profit > 5000.00
ORDER BY 
    rs.sales_rank;
