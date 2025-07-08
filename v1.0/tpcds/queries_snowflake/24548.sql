
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND ws_item_sk IS NOT NULL
    GROUP BY 
        ws_item_sk
), 
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_sales,
        rs.order_count,
        rs.ws_item_sk
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank_sales <= 10
), 
CustomerCount AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 1
    UNION ALL
    SELECT 
        'Unknown' AS c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) 
    FROM 
        web_sales ws
    WHERE 
        ws.ws_bill_customer_sk IS NULL
), 
InventoryDetails AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)

SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_sales,
    tsi.order_count,
    COALESCE(cc.total_orders, 0) AS customer_orders,
    COALESCE(id.total_on_hand, 0) AS inventory_stock
FROM 
    TopSellingItems tsi
LEFT JOIN 
    CustomerCount cc ON cc.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL ORDER BY RANDOM() LIMIT 1)
LEFT JOIN 
    InventoryDetails id ON tsi.ws_item_sk = id.inv_item_sk
WHERE 
    tsi.total_sales > (SELECT AVG(total_sales) FROM TopSellingItems)
ORDER BY 
    tsi.total_sales DESC,
    tsi.order_count ASC
LIMIT 10;
