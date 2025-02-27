
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ranked.total_quantity,
        ranked.total_profit
    FROM 
        item i
    JOIN 
        RankedSales ranked ON i.i_item_sk = ranked.ws_item_sk
    WHERE 
        ranked.profit_rank <= 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.net_paid) AS total_spent,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerRankedSales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        cs.total_transactions,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM 
        CustomerSales cs
)
SELECT 
    crs.c_customer_id,
    crs.total_spent,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_profit
FROM 
    CustomerRankedSales crs
JOIN 
    TopItems ti ON ti.total_profit > 0
WHERE 
    crs.customer_rank <= 50
ORDER BY 
    crs.total_spent DESC, ti.total_profit DESC;
