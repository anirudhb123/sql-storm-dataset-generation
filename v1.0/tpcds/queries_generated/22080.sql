
WITH RECURSIVE sales_data AS (
    SELECT 
        s.store_sk, 
        s.store_name, 
        ss.sold_date_sk, 
        SUM(ss.net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY s.store_sk ORDER BY SUM(ss.net_profit) DESC) AS profit_rank
    FROM store s
    JOIN store_sales ss ON s.store_sk = ss.store_sk
    GROUP BY s.store_sk, s.store_name, ss.sold_date_sk
),
profit_threshold AS (
    SELECT 
        AVG(total_profit) AS avg_profit,
        MAX(total_profit) AS max_profit
    FROM sales_data
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' OR (cd.cd_gender = 'F' AND cd.cd_purchase_estimate > 1000)
),
item_analysis AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COUNT(cs.cs_order_number) AS total_sales,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM item i
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
high_performance_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        total_sales,
        avg_sales_price,
        total_net_profit
    FROM item_analysis i
    WHERE i.total_sales > 50 AND i.avg_sales_price IS NOT NULL
),
return_analysis AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
final_report AS (
    SELECT 
        c.c_first_name, 
        c.c_last_name,
        ca.city AS customer_city,
        ca.state AS customer_state,
        i.i_item_id,
        hp.total_sales,
        hp.avg_sales_price,
        hp.total_net_profit,
        ra.total_returns,
        ra.total_return_amount,
        CASE 
            WHEN ra.total_returns IS NULL THEN 'No Returns'
            WHEN ra.total_return_amount = 0 THEN 'Returned but no value'
            ELSE CONCAT('Returned: ', ra.total_returns, ' with amount: ', ra.total_return_amount)
        END AS return_status,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY hp.total_net_profit DESC) AS customer_rank
    FROM customer_details c
    JOIN high_performance_items hp ON c.c_customer_sk = hp.i_item_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN return_analysis ra ON hp.i_item_sk = ra.wr_item_sk
    WHERE c_cd_credit_rating IS NOT NULL
)
SELECT DISTINCT 
    f.customer_city, 
    f.customer_state,
    COUNT(DISTINCT f.c_customer_sk) AS number_of_customers,
    SUM(f.total_net_profit) AS total_profit_generated,
    AVG(f.avg_sales_price) AS avg_profit_per_customer,
    f.return_status
FROM final_report f
JOIN profit_threshold pt ON f.total_net_profit > pt.avg_profit
GROUP BY f.customer_city, f.customer_state, f.return_status
ORDER BY total_profit_generated DESC, number_of_customers ASC;
