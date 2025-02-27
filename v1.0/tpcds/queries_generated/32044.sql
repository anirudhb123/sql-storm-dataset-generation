
WITH RECURSIVE recent_sales AS (
    SELECT ws_sold_date_sk, ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT cs_sold_date_sk, cs_item_sk, SUM(cs_quantity) AS total_quantity, SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cs_sold_date_sk, cs_item_sk
),
customer_summary AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender,
           SUM(ws_ext_sales_price) AS total_web_sales,
           SUM(ss_ext_sales_price) AS total_store_sales,
           COUNT(DISTINCT wr_order_number) AS total_web_returns
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
item_ranked AS (
    SELECT ir.ws_item_sk, ir.total_quantity, ir.total_profit,
           RANK() OVER (ORDER BY ir.total_profit DESC) AS sales_rank
    FROM recent_sales ir
)
SELECT cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.total_web_sales, 
       cs.total_store_sales, cs.total_web_returns, 
       ir.total_quantity, ir.total_profit, 
       COALESCE(ir.sales_rank, 'N/A') AS item_sales_rank
FROM customer_summary cs
LEFT JOIN item_ranked ir ON cs.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = ir.ws_item_sk)
WHERE (cs.total_web_sales > 1000 OR cs.total_store_sales > 1000)
  AND cs.total_web_returns IS NOT NULL
ORDER BY cs.total_web_sales DESC, cs.total_store_sales DESC;
