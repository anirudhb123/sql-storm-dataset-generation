
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
TopItems AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        item.i_product_name,
        sales.total_quantity,
        sales.total_sales,
        RANK() OVER (PARTITION BY item.i_item_sk ORDER BY sales.total_sales DESC) AS sales_rank
    FROM 
        SalesData sales
    JOIN 
        item AS item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.total_sales > 0
), 
CustomerSales AS (
    SELECT 
        customer.c_customer_sk,
        SUM(ws.net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales AS ws
    JOIN 
        customer AS customer ON ws.ws_ship_customer_sk = customer.c_customer_sk
    GROUP BY 
        customer.c_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics AS cd ON cs.c_customer_sk = cd.cd_demo_sk
)

SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT cs.c_customer_sk) AS count_customers,
    SUM(cs.total_sales) AS total_sales,
    AVG(cs.total_orders) AS avg_orders,
    COUNT(DISTINCT ti.i_item_id) AS items_sold
FROM 
    CustomerDemographics cd
JOIN 
    TopItems ti ON ti.item_sk = (SELECT TOP 1 i_item_sk FROM TopItems ORDER BY sales_rank ASC)
JOIN 
    CustomerSales cs ON cs.c_customer_sk = cd.cd_demo_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_sales DESC
LIMIT 100;
