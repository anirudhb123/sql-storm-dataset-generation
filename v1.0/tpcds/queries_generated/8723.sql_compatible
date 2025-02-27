
WITH sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        d.d_year = 2022 
        AND cd.cd_gender = 'M' 
        AND cd.cd_marital_status = 'M' 
        AND i.i_current_price > 50.00
    GROUP BY 
        d.d_year
), inventory_summary AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
), combined_summary AS (
    SELECT 
        s.s_store_sk,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.avg_profit, 0) AS avg_profit,
        COALESCE(ss.unique_customers, 0) AS unique_customers,
        is.total_quantity
    FROM 
        store s
    LEFT JOIN 
        sales_summary ss ON 1=1
    LEFT JOIN 
        inventory_summary is ON s.s_store_sk = is.inv_warehouse_sk
)
SELECT 
    cs.s_store_sk,
    cs.total_sales,
    cs.total_orders,
    cs.avg_profit,
    cs.unique_customers,
    cs.total_quantity,
    (cs.total_sales / NULLIF(cs.total_orders, 0)) AS avg_sales_per_order,
    (CASE 
        WHEN cs.total_quantity > 0 THEN 'In Stock' 
        ELSE 'Out of Stock' 
    END) AS stock_status
FROM 
    combined_summary cs
ORDER BY 
    cs.total_sales DESC
LIMIT 10;
