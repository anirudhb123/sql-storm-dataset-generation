
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Top_Items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_sales,
        ROW_NUMBER() OVER (ORDER BY sales.total_sales DESC) AS rank
    FROM 
        Sales_CTE sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.sales_rank = 1
),
Item_Inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
Item_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_month = 12 OR c.c_birth_month IS NULL
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ii.total_quantity_on_hand,
    id.customer_count,
    (CASE 
        WHEN ti.total_sales > 1000 THEN 'High Sales'
        WHEN ti.total_sales BETWEEN 500 AND 1000 THEN 'Medium Sales'
        ELSE 'Low Sales' 
    END) AS sales_category
FROM 
    Top_Items ti
LEFT JOIN 
    Item_Inventory ii ON ti.i_item_id = ii.inv_item_sk
LEFT JOIN 
    Item_Demographics id ON ti.rank <= 10
WHERE 
    (ti.total_quantity > 0 AND id.customer_count IS NOT NULL)
ORDER BY 
    ti.total_sales DESC;
