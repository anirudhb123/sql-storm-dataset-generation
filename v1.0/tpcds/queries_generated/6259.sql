
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        sd.total_sales,
        sd.total_orders,
        sd.total_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.total_sales > 1000
),
CustomerData AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_sales) AS gender_sales,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        Customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesData sd ON c.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk IN (SELECT ws_item_sk FROM TopItems WHERE sales_rank <= 10))
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.gender_sales,
    cd.customer_count,
    COALESCE(TOP_ITEMS.sales_rank, 0) AS top_items_sold
FROM 
    CustomerData cd
LEFT JOIN 
    (SELECT 
        i_item_id,
        sales_rank 
    FROM 
        TopItems) TOP_ITEMS ON cd.gender_sales = TOP_ITEMS.total_sales
ORDER BY 
    cd.gender_sales DESC, 
    cd.customer_count DESC;
