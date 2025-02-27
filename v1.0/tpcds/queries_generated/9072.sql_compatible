
WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_amount,
        SUM(ws_ext_discount_amt) AS total_discount_amount,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        w.warehouse_id
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk, w.warehouse_id
),
TopItems AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity_sold,
        ss.total_sales_amount,
        ss.total_discount_amount,
        ss.total_orders,
        ROW_NUMBER() OVER (PARTITION BY ss.warehouse_id ORDER BY ss.total_sales_amount DESC) AS rank
    FROM 
        SalesSummary ss
),
CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_web_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        c.c_customer_sk
),
FinalReport AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_quantity_sold,
        ti.total_sales_amount,
        cs.total_spent,
        cs.total_web_orders
    FROM 
        TopItems ti
    LEFT JOIN 
        CustomerSales cs ON ti.ws_item_sk = cs.c_customer_sk
    WHERE 
        ti.rank <= 10
)

SELECT 
    ti.ws_item_sk,
    ti.total_quantity_sold,
    ti.total_sales_amount,
    cs.total_spent,
    cs.total_web_orders
FROM 
    FinalReport ti
LEFT JOIN 
    customer_demographics cd ON ti.ws_item_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' AND 
    cd.cd_marital_status = 'M'
ORDER BY 
    ti.total_sales_amount DESC;
