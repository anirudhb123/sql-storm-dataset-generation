
WITH RecursiveSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
),
DiscountedSales AS (
    SELECT 
        r.ws_item_sk,
        COUNT(*) AS total_discounted_sales,
        SUM(r.ws_ext_sales_price) AS total_sales_value,
        SUM(r.ws_ext_discount_amt) AS total_discount_value
    FROM 
        RecursiveSales r
    WHERE 
        r.rn <= 10 AND r.ws_ext_discount_amt > 0
    GROUP BY 
        r.ws_item_sk
),
SalesSummary AS (
    SELECT 
        d.ws_item_sk,
        d.total_discounted_sales,
        d.total_sales_value,
        d.total_discount_value,
        COALESCE(d.total_discount_value / NULLIF(d.total_sales_value, 0), 0) AS discount_ratio
    FROM 
        DiscountedSales d
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    ss.total_discounted_sales,
    ss.total_sales_value,
    ss.total_discount_value,
    ss.discount_ratio,
    CASE 
        WHEN ss.discount_ratio IS NULL THEN 'No Discounts'
        WHEN ss.discount_ratio > 0.5 THEN 'High Discount'
        WHEN ss.discount_ratio BETWEEN 0.2 AND 0.5 THEN 'Moderate Discount'
        ELSE 'Low Discount'
    END AS discount_category
FROM 
    SalesSummary ss
JOIN 
    item ON item.i_item_sk = ss.ws_item_sk
LEFT JOIN 
    customer c ON c.c_customer_sk = (
        SELECT 
            ws_bill_customer_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_item_sk = ss.ws_item_sk 
            AND ws.ws_order_number = (
                SELECT MIN(ws_order_number)
                FROM web_sales 
                WHERE ws_item_sk = ss.ws_item_sk
            )
        LIMIT 1
    )
WHERE 
    c.c_birth_year BETWEEN 1980 AND 2000
    AND EXISTS (
        SELECT 1 
        FROM customer_demographics cd 
        WHERE cd.cd_demo_sk = c.c_current_cdemo_sk 
        AND cd.cd_gender = 'F'
    )
ORDER BY 
    ss.discount_ratio DESC, 
    ss.total_sales_value DESC
FETCH FIRST 20 ROWS ONLY;
