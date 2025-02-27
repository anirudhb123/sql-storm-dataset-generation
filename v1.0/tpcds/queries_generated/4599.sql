
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 10
),
OutOfStockItem AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
    HAVING 
        SUM(inv.inv_quantity_on_hand) = 0
)
SELECT 
    r.sales_rank,
    i.i_item_id,
    COALESCE(hc.order_count, 0) AS high_value_order_count,
    o.total_quantity AS out_of_stock
FROM 
    RankedSales r
LEFT JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
LEFT JOIN 
    HighValueCustomers hc ON i.i_item_sk = hc.c_customer_id
LEFT JOIN 
    OutOfStockItem o ON i.i_item_sk = o.inv_item_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank;
