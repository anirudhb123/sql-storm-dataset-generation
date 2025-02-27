
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        s.s_store_name AS store_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, s.s_store_name
),
customer_summary AS (
    SELECT 
        cd.cd_gender AS customer_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
inventory_summary AS (
    SELECT 
        i.i_category AS item_category,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        AVG(i.i_current_price) AS average_price
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_category
)
SELECT 
    ss.sales_year, 
    ss.sales_month, 
    ss.store_name, 
    ss.total_sales, 
    ss.total_orders, 
    ss.total_profit,
    cs.customer_gender,
    cs.total_customers,
    cs.total_purchase_estimate,
    is.item_category,
    is.total_quantity_on_hand,
    is.average_price
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.total_sales > 10000
JOIN 
    inventory_summary is ON ss.total_profit > 1000
ORDER BY 
    ss.sales_year, ss.sales_month, ss.total_sales DESC;
