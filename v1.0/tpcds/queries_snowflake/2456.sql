
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales
    FROM 
        customer c
    JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
),
ItemSold AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sold
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
),
MaxSold AS (
    SELECT MAX(total_sold) AS max_total_sold FROM ItemSold
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    COALESCE(
        (SELECT 
            i.i_item_id
        FROM 
            ItemSold i
        JOIN 
            MaxSold ms ON i.total_sold = ms.max_total_sold
        FETCH FIRST 1 ROW ONLY), 
        'No Sales') AS top_selling_item,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (
        SELECT c.c_current_cdemo_sk
        FROM customer c
        WHERE c.c_customer_sk = tc.c_customer_sk
    )
ORDER BY 
    tc.total_sales DESC
LIMIT 100;
