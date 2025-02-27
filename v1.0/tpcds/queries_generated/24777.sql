
WITH RankedCustomers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
),
HighValueCustomers AS (
    SELECT
        c.customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        ws.ws_net_profit > 0
    GROUP BY
        c.customer_id
    HAVING
        SUM(ws.ws_net_profit) > (SELECT AVG(ws_net_profit) FROM web_sales)
),
ItemSales AS (
    SELECT
        i.i_item_id,
        COUNT(DISTINCT ws.ws_order_number) as sales_count,
        AVG(ws.ws_sales_price) as avg_sales_price
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31')
    GROUP BY
        i.i_item_id
),
Promotions AS (
    SELECT
        p.p_promo_id,
        COUNT(ws.ws_order_number) AS promo_count
    FROM
        promotion p
    LEFT JOIN
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY
        p.p_promo_id
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    HVC.total_profit,
    HVC.total_quantity,
    ISales.sales_count,
    ISales.avg_sales_price,
    COALESCE(Pr.promo_count, 0) AS promo_count
FROM 
    RankedCustomers rc
LEFT JOIN 
    HighValueCustomers HVC ON rc.c_customer_id = HVC.customer_id
LEFT JOIN 
    ItemSales ISales ON ISales.i_item_id = (SELECT i.i_item_id FROM item i ORDER BY RANDOM() LIMIT 1)
LEFT JOIN 
    Promotions Pr ON Pr.promo_count > 5
WHERE 
    rc.rn <= 10
ORDER BY 
    HVC.total_profit DESC NULLS LAST, ISales.sales_count DESC;
