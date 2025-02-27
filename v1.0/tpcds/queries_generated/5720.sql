
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, ws.ws_sold_date_sk
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        RankedSales.total_quantity,
        RankedSales.total_sales
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        RankedSales.sales_rank <= 10
)
SELECT 
    T.total_quantity,
    T.total_sales,
    item.i_category,
    item.i_brand,
    warehouse.w_warehouse_name,
    MAX(dd.d_date) AS last_sale_date
FROM 
    TopSales T
JOIN 
    inventory inv ON T.ws_item_sk = inv.inv_item_sk
JOIN 
    warehouse ON inv.inv_warehouse_sk = warehouse.w_warehouse_sk
JOIN 
    date_dim dd ON T.ws_sold_date_sk = dd.d_date_sk
GROUP BY 
    T.total_quantity, T.total_sales, item.i_category, item.i_brand, warehouse.w_warehouse_name
ORDER BY 
    T.total_sales DESC;
