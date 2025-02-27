
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sold_date_sk,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_quantity DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = (
            SELECT d_month_seq FROM date_dim WHERE d_year = 2023 AND d_month_seq = 3
        ) LIMIT 1
    )
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
), 
MostProfitable AS (
    SELECT 
        cus.c_first_name,
        cus.c_last_name,
        cus.total_profit,
        RANK() OVER (ORDER BY cus.total_profit DESC) AS profit_rank
    FROM CustomerStats cus
    WHERE cus.total_profit > 0
)
SELECT 
    sales.ws_order_number,
    sales.ws_item_sk,
    sales.ws_quantity,
    profit.c_first_name,
    profit.c_last_name,
    profit.total_profit
FROM SalesHierarchy sales
JOIN MostProfitable profit ON sales.ws_item_sk IN (
    SELECT wp_item_sk FROM web_page wp WHERE wp.wp_web_page_sk IN (
        SELECT wp_web_page_sk FROM web_returns WHERE wr_returned_date_sk IS NOT NULL 
        UNION ALL
        SELECT wp_web_page_sk FROM catalog_sales WHERE cs_sold_date_sk IS NOT NULL
    )
) AND profit.profit_rank <= 10
ORDER BY sales.ws_order_number, sales.ws_quantity DESC;
