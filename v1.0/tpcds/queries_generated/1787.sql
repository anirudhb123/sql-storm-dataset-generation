
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        AVG(ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws_order_number) AS number_of_orders
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
AggregateSales AS (
    SELECT 
        total_quantity,
        total_sales,
        avg_profit,
        number_of_orders,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
    WHERE 
        total_sales > 1000
),
TopItems AS (
    SELECT 
        i_item_id,
        i_item_desc,
        ag.*
    FROM 
        item i
    JOIN 
        AggregateSales ag ON i.i_item_sk = ag.ws_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    ORDER BY 
        ag.sales_rank
    LIMIT 10
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    COALESCE(ti.total_quantity, 0) as total_quantity,
    COALESCE(ti.total_sales, 0) as total_sales,
    COALESCE(ti.avg_profit, 0) as avg_profit,
    CASE 
        WHEN ti.number_of_orders IS NULL THEN 'No Orders'
        ELSE CONCAT(ti.number_of_orders, ' Orders') 
    END AS orders_info,
    (SELECT COUNT(DISTINCT cd_demo_sk) 
     FROM customer_demographics
     WHERE cd_income_band_sk = (SELECT ib_income_band_sk 
                                FROM household_demographics 
                                WHERE hd_demo_sk IN (SELECT DISTINCT ws_bill_cdemo_sk FROM web_sales WHERE ws_item_sk = ti.i_item_sk)
                                LIMIT 1)) AS demographic_count
FROM 
    TopItems ti
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk 
                                                FROM customer c 
                                                JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
                                                WHERE ws.ws_item_sk = ti.i_item_sk 
                                                LIMIT 1)
ORDER BY 
    ti.total_sales DESC;

