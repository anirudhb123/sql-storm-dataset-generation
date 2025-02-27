
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        RANK() OVER (ORDER BY SUM(RS.ws_ext_sales_price) DESC) AS total_rank
    FROM 
        RankedSales RS
    JOIN 
        item ON RS.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id, item.i_product_name
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    T.i_item_id, 
    T.i_product_name,
    D.cd_gender,
    D.cd_marital_status,
    D.cd_education_status,
    D.customer_count,
    COALESCE(SUM(RS.ws_ext_sales_price), 0) AS total_sales,
    CASE 
        WHEN D.customer_count > 100 THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS engagement_level
FROM 
    TopSales T
LEFT JOIN 
    RankedSales RS ON T.ws_item_sk = RS.ws_item_sk
LEFT JOIN 
    Demographics D ON D.cd_gender = (CASE WHEN T.total_rank <= 10 THEN 'M' ELSE 'F' END)
GROUP BY 
    T.i_item_id, 
    T.i_product_name, 
    D.cd_gender, 
    D.cd_marital_status, 
    D.cd_education_status, 
    D.customer_count
HAVING 
    total_sales > 1000
ORDER BY 
    total_sales DESC;
