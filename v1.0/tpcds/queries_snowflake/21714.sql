
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM 
        web_sales ws
    WHERE
        ws.ws_net_paid_inc_tax IS NOT NULL
),
HighProfitItems AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        MAX(rs.ws_net_profit) AS max_profit
    FROM
        RankedSales rs
    JOIN 
        item ON rs.ws_item_sk = item.i_item_sk
    WHERE 
        rs.rank_profit <= 5
    GROUP BY 
        item.i_item_id, item.i_product_name
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_order_number IN (
            SELECT ws_order_number 
            FROM web_sales 
            WHERE ws_ship_date_sk IS NOT NULL 
            GROUP BY ws_order_number 
            HAVING COUNT(DISTINCT ws_item_sk) > 2
        )
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cp.c_customer_id, 
        cp.total_profit,
        RANK() OVER (ORDER BY cp.total_profit DESC) AS rank_profit
    FROM 
        CustomerPurchases cp
)
SELECT 
    hi.i_product_name,
    tc.c_customer_id,
    tc.total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
    COALESCE(SUM(ws.ws_coupon_amt), 0) AS total_coupons_redeemed,
    SUM(CASE WHEN lc.d_current_month = 'Y' THEN ws.ws_net_profit ELSE 0 END) AS profit_this_month
FROM 
    HighProfitItems hi
JOIN 
    TopCustomers tc ON tc.total_profit > 1000
LEFT JOIN 
    web_sales ws ON hi.i_item_id = ws.ws_item_sk
LEFT JOIN 
    date_dim lc ON ws.ws_sold_date_sk = lc.d_date_sk
WHERE 
    tc.rank_profit <= 10
GROUP BY 
    hi.i_product_name, tc.c_customer_id, tc.total_profit
HAVING 
    COUNT(ws.ws_order_number) > 5 OR SUM(ws.ws_net_profit) > 500
ORDER BY 
    hi.i_product_name, total_profit DESC;
