
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk,
        ws_item_sk
),
TopItems AS (
    SELECT
        ws_item_sk,
        total_sales_quantity,
        total_net_profit
    FROM
        SalesCTE
    WHERE
        rn <= 5
),
CustomerSegments AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS segments_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(case when c_preferred_cust_flag = 'Y' then 1 else 0 end) AS preferred_customers
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk,
        cd_gender
),
SalesSummary AS (
    SELECT
        ti.ws_item_sk,
        ti.total_sales_quantity,
        ti.total_net_profit,
        cs.segments_count,
        cs.avg_purchase_estimate,
        cs.preferred_customers
    FROM 
        TopItems ti
    LEFT JOIN 
        CustomerSegments cs ON cs.cd_demo_sk IN (
            SELECT 
                c.c_current_hdemo_sk 
            FROM 
                customer c 
            JOIN 
                store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
            WHERE 
                ss.ss_item_sk = ti.ws_item_sk
        )
)
SELECT
    ti.ws_item_sk,
    ti.total_sales_quantity,
    ti.total_net_profit,
    COALESCE(cs.segments_count, 0) AS segments_count,
    COALESCE(cs.avg_purchase_estimate, 0) AS avg_purchase_estimate,
    COALESCE(cs.preferred_customers, 0) AS preferred_customers,
    CASE 
        WHEN ti.total_net_profit > 10000 THEN 'High'
        WHEN ti.total_net_profit BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profitability_category
FROM 
    TopItems ti
LEFT JOIN 
    CustomerSegments cs ON cs.cd_demo_sk IS NULL OR cs.cd_demo_sk IN (
        SELECT 
            c.c_current_hdemo_sk 
        FROM 
            customer c 
        WHERE 
            c.c_current_hdemo_sk IS NOT NULL
    )
ORDER BY 
    ti.total_net_profit DESC;
