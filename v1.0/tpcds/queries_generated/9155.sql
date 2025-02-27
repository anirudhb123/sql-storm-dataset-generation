
WITH SalesSummary AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2459906 AND 2459938
    GROUP BY
        ws_sold_date_sk,
        ws_item_sk
),
TopSales AS (
    SELECT 
        ss_item_sk,
        SUM(total_profit) AS overall_profit,
        SUM(total_orders) AS overall_orders,
        AVG(avg_order_value) AS avg_order_value
    FROM 
        SalesSummary
    GROUP BY 
        ss_item_sk
    ORDER BY 
        overall_profit DESC
    LIMIT 10
)
SELECT
    t.item_id,
    t.overall_profit,
    t.overall_orders,
    t.avg_order_value,
    p.promo_name
FROM 
    TopSales t
JOIN 
    item i ON t.ss_item_sk = i.i_item_sk
JOIN 
    promotion p ON i.i_item_sk = p.p_item_sk
WHERE 
    p.p_discount_active = 'Y'
ORDER BY 
    t.overall_profit DESC;
