
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_ext_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
),
FilteredSales AS (
    SELECT
        item.i_item_id,
        SUM(sales.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT sales.ws_order_number) AS order_count
    FROM 
        SalesCTE sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.rn <= 5
    GROUP BY 
        item.i_item_id
),
RankedItems AS (
    SELECT 
        fi.i_item_id,
        fi.total_sales,
        fi.order_count,
        RANK() OVER (ORDER BY fi.total_sales DESC) AS sales_rank
    FROM 
        FilteredSales fi
)
SELECT 
    ri.i_item_id,
    ri.total_sales,
    ri.order_count,
    CASE 
        WHEN ri.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_category,
    ia.ca_city,
    ia.ca_state,
    COALESCE(ia.ca_country, 'Unknown') AS country_info
FROM 
    RankedItems ri
LEFT JOIN 
    inventory inv ON ri.i_item_id = CAST(inv.inv_item_sk AS CHAR)
LEFT JOIN 
    customer_address ia ON inv.inv_warehouse_sk = ia.ca_address_sk
WHERE 
    ri.total_sales > 1000
ORDER BY 
    ri.total_sales DESC
LIMIT 20;
