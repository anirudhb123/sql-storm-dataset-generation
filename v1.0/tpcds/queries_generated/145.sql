
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sold_date_sk,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sold_date_sk DESC) AS rn,
        SUM(ws_net_profit) OVER (PARTITION BY ws_bill_customer_sk) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(RS.total_profit, 0) AS total_profit,
        COUNT(RS.ws_item_sk) AS items_purchased,
        AVG(RS.ws_quantity) AS avg_quantity
    FROM 
        customer c
    LEFT JOIN 
        RankedSales RS ON c.c_customer_sk = RS.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM 
        SalesSummary
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    tc.items_purchased,
    tc.avg_quantity
FROM 
    TopCustomers tc
WHERE 
    tc.profit_rank <= 10
UNION ALL
SELECT 
    'Total' AS c_customer_id,
    NULL AS c_first_name,
    NULL AS c_last_name,
    SUM(total_profit) AS total_profit,
    SUM(items_purchased) AS items_purchased,
    AVG(avg_quantity) AS avg_quantity
FROM 
    TopCustomers
HAVING 
    COUNT(*) > 0;
