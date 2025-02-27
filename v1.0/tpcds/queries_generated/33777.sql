
WITH RECURSIVE SalesAggregates AS (
    SELECT 
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_order_number
),
TopProfitableSales AS (
    SELECT 
        sa.ws_order_number,
        sa.total_quantity,
        sa.total_profit,
        s.s_store_name,
        c.c_first_name,
        c.c_last_name
    FROM 
        SalesAggregates sa
    JOIN 
        store_sales s ON sa.ws_order_number = s.ss_ticket_number
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    WHERE 
        sa.rn = 1
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        d.d_year, 
        d.d_month_seq,
        cd.cd_gender, 
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_year DESC) AS year_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
)
SELECT 
    CONCAT(cd.c_first_name, ' ', cd.c_last_name) AS customer_name,
    cs.total_quantity,
    cs.total_profit,
    cs.s_store_name,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male' 
        ELSE 'Female' 
    END AS gender_description,
    cd.dep_count,
    MAX(CASE WHEN cd.year_rank = 1 THEN d.d_year END) AS latest_year
FROM 
    TopProfitableSales cs
JOIN 
    CustomerDetails cd ON cs.s_store_name = cd.year_rank
WHERE 
    cd.dep_count > 0
GROUP BY 
    cd.c_first_name, 
    cd.c_last_name, 
    cs.total_quantity, 
    cs.total_profit, 
    cs.s_store_name,
    cd.cd_gender, 
    cd.dep_count
HAVING 
    SUM(cs.total_profit) > 1000
ORDER BY 
    total_profit DESC
LIMIT 100;
