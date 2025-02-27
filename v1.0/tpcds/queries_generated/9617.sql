
WITH RankedSales AS (
    SELECT 
        ws_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_customer_sk
), 
TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        rs.total_sales
    FROM 
        customer c 
    JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_customer_sk
    WHERE 
        rs.sales_rank <= 10
),
SalesByItem AS (
    SELECT 
        ws_item_sk, 
        COUNT(ws_order_number) AS order_count, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_value
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    tc.c_customer_id,
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS customer_name,
    sbi.ws_item_sk,
    sbi.order_count,
    sbi.total_quantity,
    sbi.total_sales_value
FROM 
    TopCustomers tc
JOIN 
    SalesByItem sbi ON sbi.ws_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_bill_customer_sk = tc.c_customer_id
    )
ORDER BY 
    tc.total_sales DESC, 
    sbi.total_sales_value DESC;
