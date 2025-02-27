
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS dense_rank_price
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
        AND (c.c_birth_month BETWEEN 1 AND 6 OR c.c_birth_month IS NULL)
),
SalesSummary AS (
    SELECT 
        rs.web_site_sk,
        COUNT(rs.ws_order_number) AS total_orders,
        SUM(rs.ws_net_profit) AS total_profit,
        SUM(CASE WHEN rs.rank_profit <= 5 THEN rs.ws_net_profit ELSE 0 END) AS top_5_profit,
        AVG(rs.ws_net_profit) AS avg_profit
    FROM 
        RankedSales rs
    GROUP BY 
        rs.web_site_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS orders_count,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
FinalReport AS (
    SELECT 
        ss.web_site_sk,
        ss.total_orders,
        ss.total_profit,
        ss.top_5_profit,
        ss.avg_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.orders_count,
        cd.total_net_profit
    FROM 
        SalesSummary ss
    JOIN 
        CustomerDemographics cd ON ss.web_site_sk = (
            SELECT 
                w.w_warehouse_sk
            FROM 
                warehouse w
            WHERE 
                w.w_warehouse_sq_ft >= (SELECT AVG(w2.w_warehouse_sq_ft) FROM warehouse w2)
        )
    WHERE 
        (cd.cd_gender = 'F' AND cd.cd_marital_status IN ('S', 'M') )
        OR (cd.cd_gender = 'M' AND cd.orders_count > 100)
)
SELECT 
    fw.web_site_sk,
    fw.total_orders,
    fw.total_profit,
    fw.top_5_profit,
    fw.avg_profit,
    fw.cd_gender,
    fw.cd_marital_status,
    COALESCE(fw.orders_count, 0) AS orders_count,
    COALESCE(fw.total_net_profit, 0) AS total_net_profit,
    CASE 
        WHEN fw.total_profit > 10000 THEN 'High Profit'
        WHEN fw.total_profit BETWEEN 5000 AND 10000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    FinalReport fw
ORDER BY 
    fw.total_profit DESC NULLS LAST;
