
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31'
        )
),
TopProfitable AS (
    SELECT 
        item.i_item_id,
        COALESCE(SUM(RS.ws_net_profit), 0) AS total_profit,
        COALESCE(SUM(RS.ws_net_profit) / NULLIF(COUNT(RS.ws_order_number), 0), 0) AS avg_profit_per_order
    FROM 
        RankedSales RS
    JOIN 
        item ON RS.ws_item_sk = item.i_item_sk
    WHERE 
        RS.profit_rank <= 10
    GROUP BY 
        item.i_item_id
)

SELECT 
    C.c_country,
    C.c_gender,
    COUNT(DISTINCT CS.cs_order_number) AS total_sales_orders,
    SUM(CS.cs_net_paid) AS total_sales_amount,
    T.total_profit,
    T.avg_profit_per_order
FROM 
    customer C
LEFT JOIN 
    catalog_sales CS ON C.c_customer_sk = CS.cs_bill_customer_sk
JOIN 
    TopProfitable T ON CS.cs_item_sk = T.i_item_id
WHERE 
    C.c_birth_year < 1990
    AND C.c_current_addr_sk IS NOT NULL
GROUP BY 
    C.c_country, C.c_gender, T.total_profit, T.avg_profit_per_order
HAVING 
    SUM(CS.cs_net_paid) > 1000
ORDER BY 
    total_sales_amount DESC;
