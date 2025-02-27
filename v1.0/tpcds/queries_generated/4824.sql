
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        RANK() OVER(PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank,
        SUM(ws_quantity) OVER(PARTITION BY ws_item_sk) AS total_quantity_sold
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
TopPerformers AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        item.i_current_price,
        RankedSales.ws_sales_price,
        RankedSales.total_quantity_sold
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        RankedSales.sales_rank = 1 AND
        RankedSales.total_quantity_sold > 100
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        total_orders > 5
)
SELECT 
    cp.cp_catalog_page_id,
    cp.cp_description,
    tp.i_item_desc,
    cs.c_customer_id,
    cs.total_orders,
    cs.total_spent,
    COALESCE(SUM(ti.inv_quantity_on_hand), 0) AS total_inventory
FROM 
    catalog_page cp
LEFT JOIN 
    TopPerformers tp ON cp.cp_catalog_page_sk = (SELECT cp_catalog_page_sk FROM catalog_sales WHERE cs_item_sk = tp.i_item_id LIMIT 1)
LEFT JOIN 
    CustomerStats cs ON cs.total_spent > tp.i_current_price
FULL OUTER JOIN 
    inventory ti ON tp.i_item_sk = ti.inv_item_sk
WHERE 
    (tp.i_current_price BETWEEN 50 AND 200 OR tp.i_current_price IS NULL)
GROUP BY 
    cp.cp_catalog_page_id, cp.cp_description, tp.i_item_desc, cs.c_customer_id, cs.total_orders, cs.total_spent
ORDER BY 
    cs.total_spent DESC
LIMIT 100;
