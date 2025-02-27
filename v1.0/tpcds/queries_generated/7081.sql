
WITH SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ss_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
TopItems AS (
    SELECT 
        sa.ws_item_sk,
        sa.total_quantity,
        sa.total_sales,
        RANK() OVER (ORDER BY sa.total_sales DESC) AS sales_rank
    FROM 
        SalesSummary sa
    WHERE 
        sa.total_sales > 5000
),
CustomerGenderSpend AS (
    SELECT 
        cs.cd_gender,
        SUM(cs.total_spent) AS total_spent_by_gender,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count
    FROM 
        CustomerSummary cs
    GROUP BY 
        cs.cd_gender
)
SELECT 
    tg.ws_item_sk,
    tg.total_quantity,
    tg.total_sales,
    cgs.total_spent_by_gender,
    cgs.customer_count
FROM 
    TopItems tg
JOIN 
    CustomerGenderSpend cgs ON tg.ws_item_sk IN (SELECT cs.warehouse_sk FROM warehouse)
WHERE 
    tg.sales_rank <= 10
ORDER BY 
    tg.total_sales DESC;
