
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws.ws_ship_date_sk IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
ItemSalesRank AS (
    SELECT 
        ir.ws_item_sk,
        ir.ws_order_number,
        ir.ws_net_profit,
        ir.sell_date,
        ir.avg_profit,
        ir.cust_order_count,
        RANK() OVER (PARTITION BY ir.sell_date ORDER BY ir.avg_profit DESC) AS rank_by_date
    FROM (
        SELECT 
            ws.ws_item_sk,
            ws.ws_order_number,
            ws.ws_net_profit,
            d.d_date AS sell_date,
            AVG(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS avg_profit,
            COUNT(DISTINCT ws.ws_order_number) OVER (PARTITION BY ws.ws_item_sk) AS cust_order_count
        FROM 
            web_sales ws
        JOIN 
            date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    ) ir
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    COALESCE(rs.ws_item_sk, 0) AS item_sold,
    COALESCE(rs.ws_order_number, -1) AS order_num,
    COALESCE(rs.ws_net_profit, 0.00) AS net_profit,
    CASE 
        WHEN cs.order_count > 5 THEN 'High'
        WHEN cs.order_count BETWEEN 1 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS customer_vip_status,
    CASE
        WHEN cs.total_spent > 1000 THEN 'Big Spender'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Moderate Spender'
        ELSE 'Low Spender'
    END AS spending_category,
    ir.rank_by_date
FROM 
    CustomerStats cs
LEFT JOIN 
    RankedSales rs ON cs.c_customer_sk = rs.ws_item_sk
FULL OUTER JOIN 
    ItemSalesRank ir ON cs.c_customer_sk = ir.cust_order_count
WHERE 
    (cs.total_spent IS NOT NULL OR rs.ws_net_profit IS NOT NULL)
    AND ir.rank_by_date IS NOT NULL
ORDER BY 
    customer_vip_status DESC,
    spending_category,
    ir.rank_by_date;
