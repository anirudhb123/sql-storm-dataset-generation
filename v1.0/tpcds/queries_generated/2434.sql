
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.total_quantity,
        r.total_revenue
    FROM 
        customer c
    INNER JOIN RankedSales r ON c.c_customer_sk = r.ws_bill_customer_sk
    WHERE 
        r.rn <= 5  -- Top 5 items purchased by each customer
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM 
        item i
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    id.i_product_name,
    id.i_current_price,
    tc.total_quantity,
    tc.total_revenue,
    CASE 
        WHEN tc.total_revenue > 1000 THEN 'High Value'
        WHEN tc.total_revenue BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    COALESCE(CAST(NULLIF(SUBSTRING(tc.c_first_name, 1, 1), '') AS CHAR(1)), 'N/A') AS first_initial
FROM 
    TopCustomers tc
LEFT JOIN 
    ItemDetails id ON tc.ws_item_sk = id.i_item_sk
ORDER BY 
    tc.total_revenue DESC, 
    tc.c_customer_id;
