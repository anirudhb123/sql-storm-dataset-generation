
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ws_sold_date_sk
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2022
    )
    UNION ALL
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cs_quantity,
        cs_net_profit,
        cs_sold_date_sk
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2022
    )
),
aggregated_sales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_net_profit) AS total_net_profit,
        SUM(sd.ws_quantity) AS total_quantity_sold
    FROM sales_data sd
    GROUP BY sd.ws_item_sk
),
qualified_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
    ORDER BY c.c_last_name
),
ranked_sales AS (
    SELECT 
        as.ws_item_sk,
        as.total_net_profit,
        as.total_quantity_sold,
        RANK() OVER (ORDER BY as.total_net_profit DESC) AS profit_rank,
        RANK() OVER (ORDER BY as.total_quantity_sold DESC) AS quantity_rank
    FROM aggregated_sales as
),
final_report AS (
    SELECT 
        r.ws_item_sk,
        r.total_net_profit,
        r.total_quantity_sold,
        q.c_customer_sk,
        q.c_first_name,
        q.c_last_name
    FROM ranked_sales r
    JOIN qualified_customers q ON r.ws_item_sk = 
        (SELECT sr_item_sk 
         FROM store_returns 
         WHERE sr_ticket_number = (SELECT MIN(sr_ticket_number) 
                                   FROM store_returns 
                                   WHERE sr_customer_sk = q.c_customer_sk))
    WHERE r.profit_rank = 1 OR r.quantity_rank = 1
)
SELECT 
    f.ws_item_sk,
    f.total_net_profit,
    f.total_quantity_sold,
    f.c_first_name,
    f.c_last_name
FROM final_report f
WHERE f.total_net_profit > (SELECT AVG(total_net_profit) FROM ranked_sales)
ORDER BY f.total_net_profit DESC
LIMIT 10;
