
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales
),
CustomerStats AS (
    SELECT 
        c_customer_sk,
        COALESCE(cd_marital_status, 'Unknown') AS marital_status,
        SUM(ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c_customer_sk, cd_marital_status
),
StoreInformation AS (
    SELECT 
        s_store_sk,
        s_store_name,
        COUNT(DISTINCT ss_ticket_number) AS total_sales
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s_store_sk, s_store_name
)
SELECT 
    cs.c_customer_sk, 
    cs.marital_status, 
    cs.total_spent,
    COALESCE(si.total_sales, 0) AS total_sales_at_store,
    SUM(CASE WHEN rs.ws_net_profit IS NULL THEN 0 ELSE 1 END) AS valid_sales_count,
    LISTAGG(DISTINCT i.i_product_name, ', ') AS related_items,
    CASE 
        WHEN cs.total_spent > 500 THEN 'High'
        WHEN cs.total_spent BETWEEN 200 AND 500 THEN 'Medium'
        ELSE 'Low'
    END AS spend_category
FROM 
    CustomerStats cs
LEFT JOIN 
    RankedSales rs ON cs.c_customer_sk = rs.ws_item_sk
LEFT JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
LEFT JOIN 
    store_sales ss ON cs.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    StoreInformation si ON ss.ss_store_sk = si.s_store_sk
GROUP BY 
    cs.c_customer_sk, cs.marital_status, cs.total_spent, si.total_sales
HAVING 
    SUM(rs.ws_net_profit) IS NULL OR COUNT(*) > 0
ORDER BY 
    cs.total_spent DESC, spend_category, cs.c_customer_sk
LIMIT 10;
