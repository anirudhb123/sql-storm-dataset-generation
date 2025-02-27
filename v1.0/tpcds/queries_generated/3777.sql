
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_rec_start_date <= CURRENT_DATE 
        AND (ws.ws_sold_date_sk BETWEEN 1 AND 365) -- Considering only the last year
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
InventoryStatus AS (
    SELECT 
        inv.inv_item_sk,
        i.i_item_desc,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COALESCE(NULLIF(SUM(inv.inv_quantity_on_hand), 0), NULL) AS inventory_check
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        inv.inv_item_sk, i.i_item_desc
)
SELECT 
    r.web_site_sk,
    r.ws_order_number,
    r.total_sales,
    i.i_item_desc,
    i.total_inventory,
    r.total_sales - i.total_inventory AS sales_inventory_difference,
    CASE 
        WHEN r.total_sales > 1000 THEN 'High Sales'
        WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    RankedSales r
FULL OUTER JOIN 
    InventoryStatus i ON r.rank = 1 -- Show only the top ranked sales from sales perspective 
WHERE 
    (r.total_sales IS NOT NULL OR i.total_inventory IS NOT NULL)
ORDER BY 
    sales_inventory_difference DESC
LIMIT 10;
