
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_item_sk
),
CustomerRanked AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_gender,
        COUNT(ws_order_number) AS purchase_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
    HAVING 
        COUNT(ws_order_number) > 5
)
SELECT 
    sa.ws_item_sk,
    sa.total_sales,
    cr.c_customer_sk,
    cr.cd_gender,
    cr.cd_marital_status
FROM 
    SalesCTE sa
JOIN 
    CustomerRanked cr ON sa.ws_item_sk IN (
        SELECT 
            cs_item_sk 
        FROM 
            catalog_sales 
        WHERE 
            cs_order_number IN (
                SELECT 
                    ws_order_number 
                FROM 
                    web_sales 
                WHERE 
                    ws_bill_customer_sk = cr.c_customer_sk
            )
    )
WHERE 
    sa.sales_rank <= 10
ORDER BY 
    sa.total_sales DESC, cr.cd_gender;
