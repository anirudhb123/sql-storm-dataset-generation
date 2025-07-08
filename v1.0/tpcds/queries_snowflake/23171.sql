
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
      AND ws.ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        item.i_item_id,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity,
        SUM(ws.ws_sales_price * COALESCE(ws.ws_quantity, 0)) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        RankedSales rs
    JOIN 
        item ON item.i_item_sk = rs.ws_item_sk
    JOIN 
        web_sales ws ON ws.ws_order_number = rs.ws_order_number
    GROUP BY 
        item.i_item_id
),
TopSales AS (
    SELECT 
        i_item_id,
        total_quantity,
        total_sales_amount,
        RANK() OVER (ORDER BY total_sales_amount DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    ts.i_item_id,
    ts.total_quantity,
    ts.total_sales_amount,
    CASE 
        WHEN ts.sales_rank = 1 THEN 'Top Seller'
        WHEN ts.sales_rank <= 5 THEN 'Top 5 Seller'
        ELSE 'Regular Seller'
    END AS seller_status,
    (SELECT 
        COUNT(DISTINCT cs.cs_order_number) 
     FROM 
        catalog_sales cs 
     WHERE 
        cs.cs_item_sk = (SELECT i_item_sk FROM item WHERE i_item_id = ts.i_item_id)
       AND cs.cs_bill_customer_sk IS NOT NULL) AS catalog_order_count,
    (SELECT 
        MAX(ws_sales_price) 
     FROM 
        web_sales 
     WHERE 
        ws_item_sk = (SELECT i_item_sk FROM item WHERE i_item_id = ts.i_item_id)
      AND ws_sales_price IS NOT NULL) AS max_web_price,
    COALESCE((SELECT 
        SUM(COALESCE(sr_return_quantity, 0)) 
     FROM 
        store_returns sr 
     WHERE 
         sr_item_sk = (SELECT i_item_sk FROM item WHERE i_item_id = ts.i_item_id)), 0) AS total_returns,
    COALESCE((SELECT 
        AVG(CASE WHEN cr_return_quantity IS NOT NULL THEN cr_return_quantity ELSE 0 END) 
     FROM 
        catalog_returns cr 
     WHERE 
        cr_item_sk = (SELECT i_item_sk FROM item WHERE i_item_id = ts.i_item_id)), 0) AS avg_catalog_return
FROM 
    TopSales ts
WHERE 
    ts.total_sales_amount > (SELECT AVG(total_sales_amount) FROM SalesSummary)
ORDER BY 
    ts.total_sales_amount DESC;
