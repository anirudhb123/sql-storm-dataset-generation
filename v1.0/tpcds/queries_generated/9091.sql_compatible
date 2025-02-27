
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_net_profit,
        d.d_month_seq,
        c.c_city,
        cd.cd_gender
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id, d.d_month_seq, c.c_city, cd.cd_gender
),
RankedSales AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders,
        average_net_profit,
        ROW_NUMBER() OVER (PARTITION BY web_site_id ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.web_site_id,
    r.total_sales,
    r.total_orders,
    r.average_net_profit,
    rd.c_city,
    rd.cd_gender
FROM 
    RankedSales r
JOIN 
    SalesData rd ON r.web_site_id = rd.web_site_id AND r.sales_rank <= 3
ORDER BY 
    r.web_site_id, r.sales_rank;
