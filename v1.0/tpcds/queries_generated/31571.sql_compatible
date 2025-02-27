
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000000 AND 1000500
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
AggregateProfits AS (
    SELECT 
        ws_item_sk,
        SUM(total_net_profit) AS aggregate_net_profit
    FROM 
        SalesData
    WHERE 
        rank <= 5
    GROUP BY 
        ws_item_sk
), 
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND cd.cd_purchase_estimate > 100
    GROUP BY 
        c.c_customer_sk, cd.cd_gender 
), 
FinalResults AS (
    SELECT 
        ca.ca_city,
        SUM(COALESCE(a.aggregate_net_profit, 0)) AS total_profit,
        COUNT(DISTINCT cd.c_customer_sk) AS unique_customers
    FROM 
        customer_address ca
    LEFT JOIN 
        AggregateProfits a ON a.ws_item_sk IN (
            SELECT ws_item_sk 
            FROM web_sales 
            WHERE ws_sold_date_sk <= 1000500
        )
    LEFT JOIN 
        CustomerData cd ON cd.total_store_profit > 0
    WHERE 
        ca.ca_state = 'CA'
    GROUP BY 
        ca.ca_city
)
SELECT 
    ca.ca_city,
    COALESCE(total_profit, 0) AS total_profit,
    unique_customers,
    CASE 
        WHEN unique_customers = 0 THEN 'No sales'
        WHEN total_profit > 10000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    FinalResults
ORDER BY 
    total_profit DESC, unique_customers DESC;
