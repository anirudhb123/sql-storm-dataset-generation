
WITH RankedItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY i.i_current_price DESC) AS price_rank
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
CustomerPromotions AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_net_paid_inc_tax > 0
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
),
PromotionalSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_net_profit,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Other'
        END AS gender_category
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_net_profit > 50
),
ItemReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns, 
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    ci.i_item_desc AS popular_item,
    ci.i_current_price AS item_price,
    SUM(s.total_profit) AS total_profit,
    COUNT(DISTINCT s.order_count) AS unique_orders,
    ir.total_returns AS return_quantity,
    ir.total_return_amount AS return_amount,
    CASE 
        WHEN COUNT(DISTINCT s.gender_category) = 1 
            THEN MAX(s.gender_category) 
        ELSE 'Mixed' 
    END AS customer_gender_category
FROM 
    RankedItems ci
LEFT JOIN 
    PromotionalSales s ON ci.i_item_sk = s.ws_order_number
LEFT JOIN 
    ItemReturns ir ON ci.i_item_sk = ir.sr_item_sk
WHERE 
    ci.price_rank <= 5
GROUP BY 
    ci.i_item_desc, ci.i_current_price, ir.total_returns
HAVING 
    SUM(s.total_profit) IS NOT NULL
ORDER BY 
    total_profit DESC NULLS LAST;
