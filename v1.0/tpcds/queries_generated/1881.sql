
WITH RankedSales AS (
    SELECT 
        ws.ship_date_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ship_date_sk, ws_item_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(CASE WHEN ws.ws_ship_mode_sk IS NOT NULL THEN ws.ws_quantity ELSE NULL END) AS avg_quantity
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender
),
TopItems AS (
    SELECT 
        ris.ship_date_sk,
        ris.ws_item_sk,
        ris.total_sales,
        cis.c_customer_sk,
        cis.order_count,
        cis.total_spent
    FROM 
        RankedSales ris
    JOIN 
        CustomerSummary cis ON ris.ws_item_sk = cis.c_customer_sk 
    WHERE 
        ris.sales_rank <= 5
)
SELECT 
    ti.ship_date_sk,
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ti.total_sales, 0) AS total_item_sales,
    COALESCE(cs.total_spent, 0) AS customer_total_spent,
    COUNT(DISTINCT ti.c_customer_sk) AS customers_count
FROM 
    TopItems ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
LEFT JOIN 
    CustomerSummary cs ON ti.c_customer_sk = cs.c_customer_sk
GROUP BY 
    ti.ship_date_sk, i.i_item_id, i.i_item_desc, ti.total_sales, cs.total_spent
ORDER BY 
    ti.ship_date_sk DESC, total_item_sales DESC;
