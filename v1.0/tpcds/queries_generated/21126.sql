
WITH SalesData AS (
    SELECT 
        w.warehouse_name,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_profit,
        ROW_NUMBER() OVER (PARTITION BY w.warehouse_name ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    JOIN warehouse w ON w.warehouse_sk = ws_warehouse_sk
    WHERE ws_sold_date_sk BETWEEN 1000 AND 10000
    GROUP BY w.warehouse_name
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        COUNT(DISTINCT ws_order_number) as total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, hd.hd_buy_potential
),
ProductData AS (
    SELECT 
        i.i_item_id,
        COUNT(ws_order_number) AS order_frequency,
        SUM(ws_ext_sales_price) AS total_generated_revenue,
        AVG(ws_sales_price) AS avg_sales_price,
        SUBSTR(i.i_item_desc, 1, 10) AS short_desc
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id, i.i_item_desc
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.hd_buy_potential,
    SUM(sd.total_sales) AS total_sales,
    COALESCE(pd.total_generated_revenue, 0) AS product_revenue,
    sd.order_count,
    sd.avg_profit
FROM CustomerData cd
LEFT JOIN SalesData sd ON cd.total_orders > 5 AND sd.sales_rank <= 3
LEFT JOIN ProductData pd ON cd.total_orders = pd.order_frequency AND cd.cd_gender IS NOT NULL
WHERE sd.total_sales IS NOT NULL OR coalesce(pd.product_revenue, 0) > 0
GROUP BY cd.c_customer_id, cd.cd_gender, cd.hd_buy_potential
HAVING SUM(sd.total_sales) > 1000 OR COUNT(cd.c_customer_id) > 10
ORDER BY total_sales DESC, product_revenue ASC NULLS LAST
LIMIT 50
UNION ALL
SELECT 
    'Total' AS c_customer_id,
    NULL AS cd_gender,
    NULL AS hd_buy_potential,
    SUM(total_sales) AS total_sales,
    SUM(product_revenue) AS product_revenue,
    NULL AS order_count,
    NULL AS avg_profit
FROM (
    SELECT
        SUM(sd.total_sales) AS total_sales,
        COALESCE(pd.total_generated_revenue, 0) AS product_revenue
    FROM CustomerData cd
    LEFT JOIN SalesData sd ON cd.total_orders > 5
    LEFT JOIN ProductData pd ON cd.total_orders = pd.order_frequency
    GROUP BY cd.c_customer_id
) AS subtotal;
