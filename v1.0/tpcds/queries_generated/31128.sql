
WITH RECURSIVE SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk,
        SUM(total_sales) AS grand_total_sales,
        COUNT(ws_sold_date_sk) AS sale_days
    FROM 
        SalesSummary
    WHERE 
        total_quantity > (
            SELECT AVG(total_quantity) FROM SalesSummary
        )
    GROUP BY 
        ws_item_sk
    ORDER BY 
        grand_total_sales DESC
    LIMIT 10
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ti.grand_total_sales,
        ti.sale_days
    FROM 
        item i
    JOIN 
        TopItems ti ON i.i_item_sk = ti.ws_item_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.grand_total_sales,
    id.sale_days,
    COALESCE(
        (SELECT 
             COUNT(DISTINCT sr_ticket_number) 
         FROM 
             store_returns sr 
         WHERE 
             sr_item_sk = id.i_item_sk 
         AND 
             sr_returned_date_sk >= (SELECT MIN(ws_sold_date_sk) FROM web_sales WHERE ws_item_sk = id.i_item_sk)),
        0
    ) AS total_returns,
    CASE 
        WHEN id.sale_days > 30 THEN 'Active'
        WHEN id.sale_days BETWEEN 15 AND 30 THEN 'Moderately Active'
        ELSE 'Inactive'
    END AS sales_activity
FROM 
    ItemDetails id
LEFT JOIN 
    customer_demographics cd ON id.sale_days > cd.cd_dep_count
ORDER BY 
    id.grand_total_sales DESC;

