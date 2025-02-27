
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        1 AS level
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d)

    UNION ALL

    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_sold_date_sk,
        sd.level + 1
    FROM 
        catalog_sales cs
    JOIN 
        SalesData sd ON cs.cs_item_sk = sd.ws_item_sk
    WHERE 
        cs.cs_sold_date_sk < sd.ws_sold_date_sk
),
SalesSummary AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        COUNT(DISTINCT sd.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY SUM(sd.ws_sales_price * sd.ws_quantity) DESC) AS rank
    FROM 
        SalesData sd
    GROUP BY 
        sd.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ss.total_sales,
    ss.total_orders,
    CASE 
        WHEN ss.rank = 1 THEN 'Top Selling Item'
        ELSE 'Regular Item'
    END AS item_status
FROM 
    SalesSummary ss
JOIN 
    item i ON ss.ws_item_sk = i.i_item_sk
LEFT JOIN 
    customer_demographics cd ON i.i_item_sk IN (
        SELECT 
            DISTINCT ws.ws_item_sk
        FROM 
            web_sales ws
        WHERE 
            ws.ws_bill_customer_sk IN (
                SELECT c.c_customer_sk 
                FROM customer c 
                WHERE c.c_current_cdemo_sk = cd.cd_demo_sk
            )
    )
WHERE 
    cd.cd_marital_status = 'M' 
    AND (cd.cd_gender = 'F' OR cd.cd_credit_rating IS NULL)
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
