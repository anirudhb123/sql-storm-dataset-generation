
WITH RankedProducts AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        SUM(CASE WHEN ws.ws_net_profit > 0 THEN 1 ELSE 0 END) AS purchase_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
TopProducts AS (
    SELECT 
        rp.i_item_id, 
        rp.i_item_desc
    FROM 
        RankedProducts rp
    WHERE 
        rp.profit_rank <= 10
),
FinalMetrics AS (
    SELECT 
        cs.c_customer_id, 
        cs.cd_gender, 
        tp.i_item_id, 
        tp.i_item_desc, 
        cs.purchase_count, 
        cs.total_spent
    FROM 
        CustomerSummary cs
    CROSS JOIN 
        TopProducts tp
)
SELECT 
    fd.c_customer_id, 
    fd.cd_gender, 
    SUM(fd.total_spent) AS overall_spent, 
    COUNT(fd.purchase_count) AS total_purchases, 
    COUNT(DISTINCT fd.i_item_id) AS distinct_items_purchased
FROM 
    FinalMetrics fd
GROUP BY 
    fd.c_customer_id, fd.cd_gender
ORDER BY 
    overall_spent DESC
LIMIT 100;
