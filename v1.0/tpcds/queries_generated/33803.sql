
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales, 
        ws_sold_date_sk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
    HAVING 
        SUM(ws_quantity) > 10
    UNION ALL
    SELECT 
        ws_item_sk, 
        total_quantity + ws_quantity, 
        total_sales + ws_ext_sales_price, 
        ws_sold_date_sk
    FROM 
        web_sales ws
    JOIN 
        SalesCTE cte ON ws.ws_item_sk = cte.ws_item_sk
    WHERE 
        ws_sold_date_sk > cte.ws_sold_date_sk
),
CustomerAnalysis AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cd.cd_credit_rating IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
),
TopItems AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        SUM(ws.ws_quantity) AS quantity_sold
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
    ORDER BY 
        quantity_sold DESC
    LIMIT 10
)
SELECT 
    COALESCE(ca.total_spent, 0) AS total_spent,
    ci.i_item_id,
    ci.i_item_desc,
    TOP_ITEMS.quantity_sold,
    DENSE_RANK() OVER (PARTITION BY ci.i_item_id ORDER BY top_items.quantity_sold DESC) AS rank
FROM 
    CustomerAnalysis ca
CROSS JOIN 
    TopItems ci
LEFT JOIN 
    SalesCTE sc ON ci.i_item_sk = sc.ws_item_sk
WHERE 
    ca.order_count > 0 AND 
    ci.quantity_sold > 100
ORDER BY 
    total_spent DESC, 
    ci.i_item_id;
