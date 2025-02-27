
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        customer c
    INNER JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_sales
    FROM 
        SalesHierarchy
    WHERE 
        sales_rank <= 10
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        i.i_product_name,
        CASE 
            WHEN ws.ws_net_profit IS NULL THEN 'No profit'
            ELSE 'Profit exists'
        END AS profit_status
    FROM 
        web_sales ws
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(sd.ws_order_number, 'N/A') AS order_number,
    COALESCE(sd.i_product_name, 'Unknown product') AS product_name,
    sd.ws_quantity,
    sd.ws_net_paid,
    sd.profit_status
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesDetails sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    sd.ws_net_paid > 0 OR sd.ws_net_paid IS NULL
ORDER BY 
    tc.total_sales DESC, tc.c_last_name ASC
LIMIT 100;
