
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT CASE WHEN ws.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'Delivery') THEN ws.ws_order_number END) AS delivery_orders,
        COUNT(DISTINCT CASE WHEN ws.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'Pickup') THEN ws.ws_order_number END) AS pickup_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year > 2020
        AND cd.cd_gender = 'F'
        AND ws.ws_quantity > 1
    GROUP BY 
        d.d_year, d.d_month_seq
),
average_metrics AS (
    SELECT 
        d_year,
        AVG(total_net_profit) AS avg_net_profit,
        AVG(total_orders) AS avg_orders,
        AVG(total_sales) AS avg_sales,
        AVG(total_discount) AS avg_discount,
        AVG(delivery_orders) AS avg_delivery_orders,
        AVG(pickup_orders) AS avg_pickup_orders
    FROM 
        sales_summary
    GROUP BY 
        d_year
)
SELECT 
    avg_metrics.d_year,
    avg_metrics.avg_net_profit,
    avg_metrics.avg_orders,
    avg_metrics.avg_sales,
    avg_metrics.avg_discount,
    avg_metrics.avg_delivery_orders,
    avg_metrics.avg_pickup_orders,
    ROW_NUMBER() OVER (ORDER BY avg_metrics.avg_net_profit DESC) AS rank
FROM 
    average_metrics
ORDER BY 
    avg_metrics.d_year;
