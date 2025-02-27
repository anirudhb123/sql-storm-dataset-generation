
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN c.c_customer_sk END) AS female_customers,
        COUNT(DISTINCT CASE WHEN cd_marital_status = 'M' THEN c.c_customer_sk END) AS married_customers
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
),
DateRange AS (
    SELECT 
        d.d_date_sk, 
        d.d_year, 
        d.d_month_seq, 
        d.d_week_seq
    FROM 
        date_dim d
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
),
TopItems AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM DateRange d)
    GROUP BY 
        i.i_item_sk, 
        i.i_item_desc
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    cm.c_customer_sk,
    cm.total_profit,
    cm.total_orders,
    ti.i_item_desc,
    ti.total_sales,
    ti.total_net_profit,
    CASE 
        WHEN cm.total_orders > 0 THEN cm.total_profit / cm.total_orders 
        ELSE NULL 
    END AS average_profit_per_order,
    CONCAT('Customer ', cm.c_customer_sk, ' with total profit: ', cm.total_profit, ' and total orders: ', cm.total_orders) AS customer_summary
FROM 
    CustomerMetrics cm
LEFT JOIN 
    TopItems ti ON cm.total_profit IS NOT NULL 
ORDER BY 
    cm.total_profit DESC, ti.total_net_profit DESC;
