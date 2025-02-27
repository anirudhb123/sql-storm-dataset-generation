
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        cs.ws_bill_customer_sk,
        cs.total_orders,
        cs.total_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM RankedSales cs
    JOIN CustomerDemographics cd ON cs.ws_bill_customer_sk = cd.c_customer_sk
    WHERE cs.rank_profit <= 10
),
SalesMetrics AS (
    SELECT 
        tc.cd_gender,
        tc.cd_marital_status,
        AVG(tc.total_profit) AS avg_profit,
        COUNT(tc.ws_bill_customer_sk) AS customer_count
    FROM TopCustomers tc
    GROUP BY tc.cd_gender, tc.cd_marital_status
),
WarehouseSalesSummary AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ss.ss_net_profit) AS warehouse_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
    FROM store_sales ss
    JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
)
SELECT 
    sm.sm_type,
    ws.warehouse_profit,
    sm.sm_carrier,
    COALESCE(sms.customer_count, 0) AS total_customers,
    ROUND((ws.warehouse_profit / NULLIF(ws.sales_count, 0)), 2) AS avg_profit_per_sale,
    CASE 
        WHEN ws.warehouse_profit > 10000 THEN 'High Profit'
        WHEN ws.warehouse_profit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit' 
    END AS profit_category
FROM WarehouseSalesSummary ws
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = (SELECT sm_ship_mode_sk FROM store_sales WHERE ss_net_profit = ws.warehouse_profit LIMIT 1)
LEFT JOIN SalesMetrics sms ON TRUE
WHERE ws.sales_count > 10
ORDER BY avg_profit_per_sale DESC;
