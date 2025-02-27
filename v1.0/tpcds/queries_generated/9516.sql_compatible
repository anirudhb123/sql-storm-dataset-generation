
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_ship_cost) AS total_shipping
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
), 
AggregateData AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count,
        avg_net_profit,
        total_discount,
        total_shipping,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    ad.web_site_id,
    ad.total_sales,
    ad.order_count,
    ad.avg_net_profit,
    ad.total_discount,
    ad.total_shipping
FROM 
    AggregateData ad
WHERE 
    ad.sales_rank <= 10
ORDER BY 
    ad.sales_rank;
