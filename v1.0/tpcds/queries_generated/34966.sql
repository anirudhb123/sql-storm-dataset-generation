
WITH RECURSIVE sales_data AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk, cs_order_number
    UNION ALL
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_order_number
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_profit) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c_info.c_customer_sk,
        c_info.cd_gender,
        c_info.cd_marital_status,
        c_info.total_spent,
        DENSE_RANK() OVER (PARTITION BY c_info.cd_gender ORDER BY c_info.total_spent DESC) AS rank
    FROM 
        customer_info c_info
)
SELECT 
    t_customer.c_customer_sk,
    t_customer.cd_gender,
    COALESCE(t_customer.cd_marital_status, 'Unknown') AS marital_status,
    t_customer.total_spent,
    s.item_list
FROM 
    top_customers t_customer
LEFT JOIN (
    SELECT 
        sd.cs_item_sk,
        STRING_AGG(DISTINCT CONCAT('Order#', sd.cs_order_number, ': ', sd.total_quantity, ' units', ' (Profit: ', ROUND(sd.total_profit, 2), ')') ORDER BY sd.cs_order_number) AS item_list
    FROM 
        sales_data sd
    GROUP BY 
        sd.cs_item_sk
) s ON t_customer.c_customer_sk = s.cs_item_sk
WHERE 
    t_customer.rank <= 5
ORDER BY 
    t_customer.cd_gender, t_customer.total_spent DESC;
