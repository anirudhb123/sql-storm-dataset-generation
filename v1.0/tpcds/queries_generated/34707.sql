
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        1 AS level
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) + COALESCE(SUM(ws_quantity), 0),
        SUM(cs_net_paid) + COALESCE(SUM(ws_net_paid), 0),
        level + 1
    FROM 
        catalog_sales
    LEFT JOIN web_sales ON web_sales.ws_item_sk = catalog_sales.cs_item_sk
    GROUP BY 
        cs_item_sk, level
),
SalesSummary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        c.cd_gender,
        SUM(s.total_quantity) AS total_quantity_sold,
        SUM(s.total_sales) AS total_sales_revenue
    FROM 
        item i
    LEFT JOIN SalesCTE s ON i.i_item_sk = s.ws_item_sk
    LEFT JOIN customer c ON c.c_customer_sk = s.ws_bill_customer_sk
    GROUP BY 
        i.i_item_id,
        i.i_item_desc,
        c.cd_gender
),
RankedSales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_sales_revenue DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    item_id,
    item_desc,
    cd_gender,
    total_quantity_sold,
    total_sales_revenue
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
ORDER BY 
    cd_gender ASC, 
    total_sales_revenue DESC;
