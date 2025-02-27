
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_ext_sales_price) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        r.total_sales,
        r.total_revenue
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.sales_rank <= 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_ext_sales_price) > 1000
),
SalesDetail AS (
    SELECT 
        ti.i_item_id,
        ti.i_item_desc,
        ci.c_customer_id,
        ci.total_spent,
        RANK() OVER (PARTITION BY ti.i_item_id ORDER BY ci.total_spent DESC) AS customer_rank
    FROM 
        TopItems ti
    JOIN 
        CustomerInfo ci ON ti.total_revenue > ci.total_spent
)
SELECT 
    sd.i_item_id,
    sd.i_item_desc,
    sd.c_customer_id,
    sd.total_spent,
    sd.customer_rank
FROM 
    SalesDetail sd
WHERE 
    sd.customer_rank <= 5
ORDER BY 
    sd.i_item_id, sd.customer_rank;
