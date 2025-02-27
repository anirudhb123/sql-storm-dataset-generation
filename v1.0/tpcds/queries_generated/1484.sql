
WITH TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity_sold,
        sd.total_sales,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        item i
    JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
    WHERE 
        sd.total_sales > 1000
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity_sold,
    ti.total_sales,
    CASE 
        WHEN ti.sales_rank <= 10 THEN 'Top 10'
        WHEN ti.sales_rank <= 50 THEN 'Top 50'
        ELSE 'Others'
    END AS sales_category
FROM 
    TopCustomers tc
JOIN 
    TopItems ti ON EXISTS (
        SELECT 1 
        FROM web_sales ws
        WHERE 
            ws.ws_bill_customer_sk = tc.c_customer_sk 
            AND ws.ws_item_sk = ti.ws_item_sk
    )
ORDER BY 
    tc.total_spent DESC, ti.total_sales DESC;
