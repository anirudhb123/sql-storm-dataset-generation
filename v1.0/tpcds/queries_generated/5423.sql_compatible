
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(sd.total_sales) AS total_sales_per_customer
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cd.total_sales_per_customer,
        ROW_NUMBER() OVER (ORDER BY cd.total_sales_per_customer DESC) AS rank
    FROM 
        CustomerData cd
    JOIN 
        customer c ON cd.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.customer_id,
    tc.total_sales_per_customer,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top 10'
        WHEN tc.rank <= 50 THEN 'Top 50'
        ELSE 'Other'
    END AS sales_category
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 100;
