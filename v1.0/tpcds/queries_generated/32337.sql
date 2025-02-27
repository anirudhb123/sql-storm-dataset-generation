
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        hd_income_band_sk,
        cd_purchase_estimate
    FROM 
        customer_demographics
    JOIN household_demographics ON cd_demo_sk = hd_demo_sk
),
WarehouseSummary AS (
    SELECT 
        w_warehouse_sk,
        AVG(w_warehouse_sq_ft) AS avg_sq_ft
    FROM 
        warehouse
    GROUP BY 
        w_warehouse_sk
)

SELECT 
    c.c_customer_id,
    cd.gender,
    COALESCE(cd.marital_status, 'Unknown') AS marital_status,
    ss.total_net_profit,
    ss.total_orders,
    wh.avg_sq_ft,
    (SELECT COUNT(*) 
     FROM store_sales ss2 
     WHERE ss2.ss_customer_sk = c.c_customer_sk 
     AND ss2.ss_sold_date_sk BETWEEN 20220101 AND 20220131) AS store_sales_count,
    (SELECT SUM(ws_ext_sales_price) 
     FROM web_sales 
     WHERE ws_bill_customer_sk = c.c_customer_sk 
     AND ws_sold_date_sk > (
         SELECT MAX(ws_sold_date_sk) 
         FROM web_sales 
         WHERE ws_bill_customer_sk = c.c_customer_sk 
         AND ws_net_profit > 0)
    ) AS additional_web_sales

FROM 
    customer c
LEFT JOIN 
    SalesCTE ss ON c.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    WarehouseSummary wh ON wh.w_warehouse_sk = (
        SELECT inv.warehouse_sk 
        FROM inventory inv 
        WHERE inv.inv_item_sk IN (
            SELECT ws.ws_item_sk 
            FROM web_sales ws 
            WHERE ws.ws_bill_customer_sk = c.c_customer_sk
        )
        LIMIT 1
    )
WHERE 
    ss.rank <= 10
ORDER BY 
    ss.total_net_profit DESC;
