
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451000 AND 2451500
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), RankCTE AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.total_sales, 0) AS total_sales,
        s.sales_rank
    FROM 
        item
    LEFT JOIN SalesCTE s ON item.i_item_sk = s.ws_item_sk
), CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_first_name) AS customer_rank
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cd.cd_gender = 'F' AND 
        cd.cd_purchase_estimate > 1000
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    r.i_item_id,
    r.total_quantity,
    r.total_sales,
    r.sales_rank,
    cc.c_birth_month,
    CASE 
        WHEN r.total_sales IS NULL THEN 'No Sales'
        WHEN r.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller' 
    END AS sales_category
FROM 
    RankCTE r
JOIN 
    CustomerCTE cc ON r.sales_rank = cc.customer_rank
WHERE 
    r.total_sales > 0 AND 
    cc.c_birth_month IS NOT NULL
ORDER BY 
    r.total_sales DESC, 
    cc.c_last_name ASC
LIMIT 50;
