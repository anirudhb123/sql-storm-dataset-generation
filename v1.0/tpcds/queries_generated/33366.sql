
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_brand, 
        0 AS level
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND i.i_rec_end_date >= CURRENT_DATE

    UNION ALL

    SELECT 
        ih.i_item_sk,
        CONCAT(ih.i_item_desc, ' (Related)') AS i_item_desc,
        ih.i_brand,
        level + 1
    FROM 
        item ih
    INNER JOIN ItemHierarchy ihier ON ih.i_item_sk = ihier.i_item_sk
    WHERE 
        ih.i_rec_start_date <= CURRENT_DATE AND ih.i_rec_end_date >= CURRENT_DATE
),
SalesStatistics AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS employed_count,
        COALESCE(cd.cd_dep_college_count, 0) AS college_count,
        ss.total_sales,
        ss.total_orders,
        ss.sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        SalesStatistics ss ON c.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    c.cd_gender,
    c.total_sales,
    c.total_orders,
    c.sales_rank,
    i.i_item_desc,
    i.level
FROM 
    CustomerDetails c
LEFT JOIN 
    ItemHierarchy i ON i.i_item_sk IN (
        SELECT inv.inv_item_sk 
        FROM inventory inv 
        WHERE inv.inv_quantity_on_hand > 50
    )
WHERE 
    c.total_sales IS NOT NULL
    AND (c.cd_marital_status = 'M' OR c.cd_purchase_estimate > 500)
ORDER BY 
    c.total_sales DESC, 
    c.sales_rank ASC
LIMIT 100;
