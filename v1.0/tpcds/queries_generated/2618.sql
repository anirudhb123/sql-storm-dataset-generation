
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        customer.c_customer_sk,
        customer.c_first_name,
        customer.c_last_name,
        RankedSales.total_sales
    FROM 
        customer
    JOIN 
        RankedSales ON customer.c_customer_sk = RankedSales.ws_bill_customer_sk
    WHERE 
        RankedSales.sales_rank <= 5
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        COUNT(*) AS sale_count,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_net_paid_inc_tax) AS avg_price
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(is.item_sales, 0) AS num_items_sold,
    COALESCE(is.total_quantity, 0) AS total_quantity,
    COALESCE(is.avg_price, 0) AS avg_price,
    CASE 
        WHEN tc.total_sales > 1000 THEN 'VIP'
        ELSE 'Regular'
    END AS customer_category
FROM 
    TopCustomers tc
LEFT JOIN 
    (
        SELECT 
            item.i_item_sk,
            SUM(ws_quantity) AS item_sales,
            SUM(ws_quantity) * AVG(ws_net_paid_inc_tax) AS total_quantity,
            AVG(ws_net_paid_inc_tax) AS avg_price
        FROM 
            web_sales ws
        JOIN 
            item i ON ws.ws_item_sk = i.i_item_sk
        GROUP BY 
            item.i_item_sk
    ) is ON is.ws_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_sk)
ORDER BY 
    tc.total_sales DESC;
