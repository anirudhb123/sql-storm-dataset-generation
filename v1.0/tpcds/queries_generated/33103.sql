
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
AggregatedSales AS (
    SELECT 
        ss_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        SalesCTE
    GROUP BY 
        ss_item_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(AS.total_quantity, 0) AS total_quantity,
        COALESCE(AS.total_net_profit, 0) AS total_net_profit,
        COUNT(ws_order_number) OVER (PARTITION BY c.c_customer_id) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        AggregatedSales AS ON c.c_customer_sk = AS.ss_item_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
),
FinalReport AS (
    SELECT 
        cs.c_customer_id,
        CONCAT(cs.c_first_name, ' ', cs.c_last_name) AS full_name,
        cs.total_quantity,
        cs.total_net_profit,
        CASE 
            WHEN cs.order_count > 5 THEN 'Frequent'
            WHEN cs.order_count BETWEEN 2 AND 5 THEN 'Occasional'
            ELSE 'Rare'
        END AS customer_type
    FROM 
        CustomerSales cs
)
SELECT 
    DISTINCT lr.*,
    CASE 
        WHEN lr.total_net_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Exists'
    END AS sale_status,
    RANK() OVER (ORDER BY lr.total_net_profit DESC) AS profit_rank
FROM 
    FinalReport lr
WHERE 
    lr.total_quantity > 0
ORDER BY 
    lr.total_net_profit DESC
LIMIT 100;
