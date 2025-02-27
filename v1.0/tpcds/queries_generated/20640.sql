
WITH CustomerRank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
SalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_net_profit) AS max_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        CASE 
            WHEN (LOWER(i.i_color) LIKE '%red%' OR LOWER(i.i_color) LIKE '%blue%') THEN 'Color_Choice'
            ELSE 'Other_Color'
        END AS color_category,
        i.i_current_price,
        IIF(i.i_current_price IS NULL, 0, i.i_current_price * 0.1) AS price_adjustment
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
SalesAnalysis AS (
    SELECT 
        cr.c_customer_sk, 
        cr.total_sales, 
        CASE 
            WHEN cr.total_sales > 1000 THEN 'High Value'
            WHEN cr.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        CASE 
            WHEN id.color_category = 'Color_Choice' THEN SUM(id.i_current_price + id.price_adjustment)
            ELSE NULL
        END AS category_sales
    FROM 
        SalesData cr
    JOIN 
        CustomerRank r ON cr.ws_bill_customer_sk = r.c_customer_sk
    LEFT JOIN 
        ItemDetails id ON cr.ws_bill_customer_sk = r.c_customer_sk
    GROUP BY 
        cr.c_customer_sk, cr.total_sales, id.color_category
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    sa.customer_value,
    COALESCE(SUM(sa.category_sales), 0) AS total_category_sales,
    r.cd_gender,
    r.cd_marital_status,
    AVG(sa.total_sales) OVER (PARTITION BY r.cd_gender) AS avg_sales_by_gender,
    COUNT(DISTINCT r.c_customer_sk) AS unique_customers
FROM 
    SalesAnalysis sa
JOIN 
    CustomerRank r ON sa.c_customer_sk = r.c_customer_sk
WHERE 
    r.rn <= 10
GROUP BY 
    r.c_first_name, r.c_last_name, sa.customer_value, r.cd_gender, r.cd_marital_status
ORDER BY 
    total_category_sales DESC, avg_sales_by_gender DESC;
