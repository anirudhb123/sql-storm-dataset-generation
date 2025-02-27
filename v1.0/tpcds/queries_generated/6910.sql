
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ws_item_sk, 
        SUM(total_quantity) AS total_quantity_sold,
        SUM(total_sales) AS total_sales_amount
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        t.total_quantity_sold,
        t.total_sales_amount
    FROM 
        TopSellingItems t
    JOIN 
        item i ON t.ws_item_sk = i.i_item_sk
),
CustomerPurchaseSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        COUNT(DISTINCT ws.web_page_sk) AS total_web_pages
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    id.i_item_id,
    id.i_product_name,
    id.total_quantity_sold,
    id.total_sales_amount,
    cps.total_orders,
    cps.total_web_pages
FROM 
    ItemDetails id
JOIN 
    CustomerPurchaseSummary cps ON cps.c_customer_sk = (SELECT c_customer_sk FROM customer ORDER BY RANDOM() LIMIT 1)
ORDER BY 
    id.total_sales_amount DESC;
