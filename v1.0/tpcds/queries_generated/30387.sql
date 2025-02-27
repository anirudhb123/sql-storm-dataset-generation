
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_current_cdemo_sk, 
        1 as level
    FROM 
        customer c
    WHERE 
        c.c_current_addr_sk IS NOT NULL

    UNION ALL

    SELECT 
        ch.c_customer_sk, 
        ch.c_first_name, 
        ch.c_last_name, 
        ch.c_current_cdemo_sk, 
        ch.level + 1 
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk 
    WHERE 
        ch.level < 5
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit,
        ARRAY_AGG(DISTINCT sm.sm_type) AS ship_modes
    FROM 
        web_sales ws
    LEFT JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_item_sk
),
QualifiedCustomers AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT customer.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer ON cd.cd_demo_sk = customer.c_current_cdemo_sk
    WHERE 
        cd.cd_marital_status = 'M' AND
        cd.cd_credit_rating IN ('High', 'Medium')
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
Summary AS (
    SELECT 
        ch.c_first_name,
        ch.c_last_name,
        qc.cd_demo_sk,
        qc.cd_gender,
        qc.cd_marital_status,
        sd.total_sold,
        sd.total_profit,
        ROW_NUMBER() OVER (PARTITION BY qc.cd_demo_sk ORDER BY sd.total_profit DESC) AS rank
    FROM 
        CustomerHierarchy ch
    JOIN 
        QualifiedCustomers qc ON ch.c_current_cdemo_sk = qc.cd_demo_sk
    LEFT JOIN 
        SalesData sd ON ch.c_customer_sk = sd.ws_item_sk
    WHERE 
        sd.total_sold IS NOT NULL
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.cd_demo_sk,
    s.cd_gender,
    s.cd_marital_status,
    s.total_sold,
    s.total_profit
FROM 
    Summary s
WHERE 
    s.rank <= 3
ORDER BY 
    s.total_profit DESC
LIMIT 100;
