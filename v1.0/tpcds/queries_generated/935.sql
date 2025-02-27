
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 0
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_item_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    COALESCE(im.total_item_sales, 0) AS item_sales,
    CASE 
        WHEN tc.order_count > 10 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type
FROM 
    TopCustomers tc
LEFT JOIN 
    (SELECT 
         ws_bill_customer_sk, 
         SUM(ws.sales_price * ws.quantity) AS total_item_sales
     FROM 
         web_sales ws
     JOIN 
         ItemSales is ON ws.ws_item_sk = is.i_item_sk 
     GROUP BY 
         ws_bill_customer_sk) im ON tc.c_customer_sk = im.ws_bill_customer_sk
WHERE 
    tc.sales_rank <= 100
ORDER BY 
    tc.total_sales DESC;
