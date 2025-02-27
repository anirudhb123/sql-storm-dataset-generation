
WITH RECURSIVE RankedSales AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name, ws.ws_sold_date_sk
),
CustomerProfits AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_current_year = 'Y')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.*,
        cd.cd_gender,
        cd.cd_marital_status,
        DENSE_RANK() OVER (ORDER BY cp.total_profit DESC) AS customer_rank
    FROM 
        CustomerProfits cp
    JOIN 
        customer c ON c.c_customer_sk = cp.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cp.total_profit > (
            SELECT AVG(total_profit)
            FROM CustomerProfits
        )
)
SELECT 
    r.s_store_name,
    r.total_quantity,
    r.total_net_profit,
    h.c_first_name,
    h.c_last_name,
    h.cd_gender,
    h.cd_marital_status
FROM 
    RankedSales r
JOIN 
    HighValueCustomers h ON r.s_store_sk = (SELECT s.s_store_sk FROM store s WHERE s.s_store_name = r.s_store_name)
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.total_net_profit DESC, h.total_profit DESC
LIMIT 10;

