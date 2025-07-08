
WITH TotalSales AS (
    SELECT 
        ws_item_sk AS item_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ts.item_sk,
        ts.total_sales,
        ROW_NUMBER() OVER (ORDER BY ts.total_sales DESC) AS rank
    FROM 
        TotalSales ts
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ti.total_sales
    FROM 
        item i
    JOIN 
        TopItems ti ON i.i_item_sk = ti.item_sk
    WHERE 
        ti.rank <= 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating, 
        ti.total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        ItemDetails ti ON ti.total_sales > 1000
),
SalesAnalysis AS (
    SELECT 
        ci.c_customer_id,
        COUNT(DISTINCT ci.c_customer_id) AS customer_count,
        AVG(ci.total_sales) AS avg_sales,
        MAX(ci.total_sales) AS max_sales,
        MIN(ci.total_sales) AS min_sales
    FROM 
        CustomerInfo ci
    GROUP BY 
        ci.c_customer_id
)
SELECT 
    sa.c_customer_id,
    sa.customer_count,
    sa.avg_sales,
    sa.max_sales,
    sa.min_sales,
    d.d_year,
    d.d_month_seq
FROM 
    SalesAnalysis sa
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_ship_date_sk = d.d_date_sk)
WHERE 
    d.d_year = 2020
ORDER BY 
    sa.avg_sales DESC;
