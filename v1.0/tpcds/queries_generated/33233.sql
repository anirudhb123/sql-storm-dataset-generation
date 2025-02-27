
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT 
        si.i_item_id,
        si.i_item_desc,
        ss.total_sales,
        ss.order_count
    FROM SalesCTE ss
    JOIN item si ON ss.ws_item_sk = si.i_item_sk
    WHERE ss.rank <= 10
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
SalesDetails AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent,
    COALESCE(sd.total_catalog_sales, 0) AS total_catalog_sales,
    sd.total_quantity,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Value'
        WHEN cs.total_spent > 500 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM TopItems ti
JOIN CustomerSummary cs ON cs.total_spent > 0
LEFT JOIN SalesDetails sd ON ti.i_item_id = sd.cs_item_sk
WHERE cs.c_customer_sk IS NOT NULL
ORDER BY cs.total_spent DESC, ti.total_sales DESC;
