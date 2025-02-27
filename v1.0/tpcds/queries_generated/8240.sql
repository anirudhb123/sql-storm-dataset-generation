
WITH EnhancedSalesData AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2023
        AND cd.cd_gender = 'F'
        AND ws.ws_web_site_sk IN (SELECT web_site_sk FROM web_site WHERE web_country = 'USA')
    GROUP BY ws.web_site_id, ws.web_name
),
TopSalesData AS (
    SELECT 
        ESD.web_site_id,
        ESD.web_name,
        ESD.total_quantity_sold,
        ESD.total_sales,
        ESD.total_discount,
        ESD.total_net_paid,
        ESD.avg_net_profit,
        ESD.total_orders,
        RANK() OVER (ORDER BY ESD.total_sales DESC) AS sales_rank
    FROM EnhancedSalesData ESD
)
SELECT 
    TSD.web_site_id,
    TSD.web_name,
    TSD.total_quantity_sold,
    TSD.total_sales,
    TSD.total_discount,
    TSD.total_net_paid,
    TSD.avg_net_profit,
    TSD.total_orders
FROM TopSalesData TSD
WHERE TSD.sales_rank <= 10
ORDER BY TSD.total_sales DESC;
