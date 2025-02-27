
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.total_sales > (
            SELECT AVG(total_sales) 
            FROM customer_sales
        )
),

inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),

sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),

catalog_sales_summary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_catalog_sold
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
)

SELECT
    c.c_customer_sk,
    COALESCE(hvc.total_sales, 0) AS high_value_sales,
    COALESCE(hvc.total_orders, 0) AS high_value_orders,
    COALESCE(iv.total_quantity, 0) AS inventory_quantity,
    COALESCE(ss.total_sold, 0) AS web_sales_sold,
    COALESCE(css.total_catalog_sold, 0) AS catalog_sales_sold
FROM
    customer c
LEFT JOIN
    high_value_customers hvc ON c.c_customer_sk = hvc.c_customer_sk
LEFT JOIN
    inventory_data iv ON iv.inv_item_sk = (
        SELECT 
            i.i_item_sk
        FROM 
            item i
        ORDER BY 
            RANDOM()
        LIMIT 1
    )
LEFT JOIN 
    sales_summary ss ON ss.ws_item_sk = (
        SELECT 
            ws.ws_item_sk
        FROM 
            web_sales ws
        WHERE 
            ws.ws_bill_customer_sk = c.c_customer_sk
        ORDER BY 
            RANDOM()
        LIMIT 1
    )
LEFT JOIN
    catalog_sales_summary css ON css.cs_item_sk = (
        SELECT 
            cs.cs_item_sk
        FROM 
            catalog_sales cs
        WHERE 
            cs.cs_bill_customer_sk = c.c_customer_sk
        ORDER BY 
            RANDOM()
        LIMIT 1
    )
WHERE 
    c.c_preferred_cust_flag = 'Y'
ORDER BY 
    high_value_sales DESC
LIMIT 100;
