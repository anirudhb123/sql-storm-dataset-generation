
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count,
        cd.cd_dep_employed_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredTopCustomers AS (
    SELECT
        rs.ws_bill_customer_sk,
        rs.total_net_profit,
        rs.order_count,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        cd.cd_marital_status,
        cd.cd_dep_count
    FROM
        RankedSales rs
    JOIN
        CustomerDemographics cd ON rs.ws_bill_customer_sk = cd.c_customer_sk
    WHERE
        rs.profit_rank <= 10 AND
        (cd.cd_marital_status IS NOT NULL OR cd.cd_dep_count > 0)
),
WarehouseSales AS (
    SELECT
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS warehouse_profit
    FROM
        warehouse w
    JOIN
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY
        w.w_warehouse_id
),
CustomerWarehouseData AS (
    SELECT
        ftc.ws_bill_customer_sk,
        w.w_warehouse_id,
        SUM(wp.warehouse_profit) AS total_warehouse_profit
    FROM
        FilteredTopCustomers ftc
    JOIN
        WarehouseSales wp ON ftc.ws_bill_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        ftc.ws_bill_customer_sk, w.w_warehouse_id
)
SELECT
    ftc.ws_bill_customer_sk,
    ftc.total_net_profit,
    ftc.gender,
    ftc.cd_marital_status,
    COALESCE(cwd.total_warehouse_profit, 0) AS total_warehouse_profit,
    CASE 
        WHEN cwd.total_warehouse_profit > ftc.total_net_profit THEN 'High Engagement' 
        WHEN cwd.total_warehouse_profit < ftc.total_net_profit THEN 'Low Engagement' 
        ELSE 'Neutral Engagement' 
    END AS engagement_level
FROM
    FilteredTopCustomers ftc
LEFT JOIN
    CustomerWarehouseData cwd ON ftc.ws_bill_customer_sk = cwd.ws_bill_customer_sk
ORDER BY
    ftc.total_net_profit DESC,
    ftc.ws_bill_customer_sk;
