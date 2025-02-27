
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ws_sold_date_sk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20211231
    GROUP BY ws_item_sk, ws_sold_date_sk

    UNION ALL

    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        cs_sold_date_sk
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 20200101 AND 20211231
    GROUP BY cs_item_sk, cs_sold_date_sk
),

customer_data AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        (SELECT ib_upper_bound FROM income_band WHERE ib_income_band_sk = cd_income_band_sk) AS upper_income,
        (SELECT ib_lower_bound FROM income_band WHERE ib_income_band_sk = cd_income_band_sk) AS lower_income
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),

performance_bench AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ss.total_quantity) AS total_items_sold,
        SUM(ss.total_profit) AS total_profit
    FROM customer_data cd
    LEFT JOIN sales_summary ss ON cd.c_customer_sk = ss.ws_item_sk
    LEFT JOIN web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
    HAVING COUNT(DISTINCT ws.ws_order_number) > 0 AND SUM(ss.total_profit) IS NOT NULL
),

final_results AS (
    SELECT 
        pb.c_customer_sk,
        pb.total_orders,
        pb.total_items_sold,
        pb.total_profit,
        CASE 
            WHEN total_profit > 5000 THEN 'High Value'
            WHEN total_profit BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_value
    FROM performance_bench pb
)

SELECT 
    f.c_customer_sk,
    f.total_orders,
    f.total_items_sold,
    f.total_profit,
    f.customer_value
FROM final_results f
ORDER BY f.total_profit DESC
LIMIT 100;
