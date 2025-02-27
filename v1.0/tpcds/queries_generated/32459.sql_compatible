
WITH RECURSIVE ItemSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        COUNT(ws.order_number) AS purchase_count, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cp.purchase_count, 
        cp.total_spent
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cp.total_spent > (SELECT AVG(total_spent) FROM CustomerPurchases)
),
TopSellingItems AS (
    SELECT 
        item.i_item_sk, 
        item.i_item_desc, 
        is.total_quantity, 
        is.total_sales
    FROM 
        ItemSales is
    JOIN 
        item ON is.ws_item_sk = item.i_item_sk
    ORDER BY 
        is.total_sales DESC
    LIMIT 10
)
SELECT 
    hvc.cd_gender, 
    COUNT(DISTINCT hvc.c_customer_sk) AS high_value_count,
    SUM(tsi.total_sales) AS total_sales_from_high_value_customers
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    TopSellingItems tsi ON hvc.c_customer_sk IN (
        SELECT 
            ws.ws_bill_customer_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_item_sk IN (SELECT i_item_sk FROM item)
    )
GROUP BY 
    hvc.cd_gender
HAVING 
    COUNT(DISTINCT hvc.c_customer_sk) > 2
ORDER BY 
    total_sales_from_high_value_customers DESC;
