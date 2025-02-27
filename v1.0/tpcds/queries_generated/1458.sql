
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
HighProfitItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        AVG(RankedSales.total_profit) AS avg_profit
    FROM 
        item
    JOIN 
        RankedSales ON item.i_item_sk = RankedSales.ws_item_sk
    WHERE 
        RankedSales.profit_rank <= 5
    GROUP BY 
        item.i_item_id, item.i_item_desc
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
SalesStatistics AS (
    SELECT 
        t.d_year,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim t ON ws.ws_sold_date_sk = t.d_date_sk
    GROUP BY 
        t.d_year
),
FinalReport AS (
    SELECT 
        hpi.i_item_desc AS top_item,
        COUNT(tc.c_customer_id) AS loyal_customers,
        ss.unique_customers,
        ss.total_sales_profit
    FROM 
        HighProfitItems hpi
    CROSS JOIN 
        TopCustomers tc
    JOIN 
        SalesStatistics ss ON ss.unique_customers > 0
    GROUP BY 
        hpi.i_item_desc, ss.unique_customers, ss.total_sales_profit
)
SELECT 
    f.top_item,
    f.loyal_customers,
    f.unique_customers,
    f.total_sales_profit
FROM 
    FinalReport f
WHERE 
    f.loyal_customers > 10
ORDER BY 
    f.total_sales_profit DESC
LIMIT 10;
