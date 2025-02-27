
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS row_num
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
AggregateSales AS (
    SELECT 
        item.i_item_id,
        SUM(sales.ws_quantity) AS total_quantity,
        SUM(sales.ws_sales_price * sales.ws_quantity) AS total_sales,
        AVG(sales.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT sales.ws_sold_date_sk) AS sales_days
    FROM 
        SalesCTE sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid_inc_tax) AS total_amount_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
JoinSummary AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.cd_marital_status,
        as.total_quantity,
        as.total_sales,
        as.avg_sales_price,
        as.sales_days
    FROM 
        CustomerSummary cs
    JOIN 
        AggregateSales as ON cs.total_amount_spent > 0
    WHERE 
        cs.total_amount_spent IS NOT NULL
)
SELECT 
    j.cd_gender,
    j.cd_marital_status,
    COUNT(DISTINCT j.c_customer_id) AS total_customers,
    AVG(j.total_sales) AS avg_sales_per_customer,
    SUM(CASE WHEN j.sales_days > 1 THEN 1 ELSE 0 END) AS returning_customers,
    SUM(j.total_quantity) AS total_quantity_sold 
FROM 
    JoinSummary j
GROUP BY 
    j.cd_gender, j.cd_marital_status
ORDER BY 
    total_customers DESC
LIMIT 10;
