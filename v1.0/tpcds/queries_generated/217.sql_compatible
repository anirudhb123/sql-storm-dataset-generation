
WITH Ranked_Sales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Item_Info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_category,
        MAX(i.i_current_price) AS max_price
    FROM 
        item i
    GROUP BY 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_category
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ii.i_item_desc,
    ii.i_category,
    MAX(rs.ws_sales_price) AS max_web_sales_price,
    AVG(rs.ws_quantity) AS avg_quantity,
    COUNT(DISTINCT rs.ws_sales_price) AS distinct_price_count,
    SUM(CASE WHEN rs.ws_sales_price IS NULL THEN 1 ELSE 0 END) AS null_price_count
FROM 
    Ranked_Sales rs
JOIN 
    Customer_Info ci ON rs.ws_item_sk = ci.c_customer_sk
JOIN 
    Item_Info ii ON rs.ws_item_sk = ii.i_item_sk
WHERE 
    rs.sales_rank = 1 AND 
    ci.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM Customer_Info) AND 
    ii.max_price > 100
GROUP BY 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ii.i_item_desc,
    ii.i_category
HAVING 
    COUNT(rs.ws_sales_price) > 3
ORDER BY 
    max_web_sales_price DESC;
