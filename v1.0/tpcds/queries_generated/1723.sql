
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_orders,
        cs.total_profit,
        CASE 
            WHEN cs.total_profit > 1000 THEN 'VIP'
            WHEN cs.total_profit > 500 THEN 'Valuable'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_orders > 5
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hvc.customer_type,
    CASE 
        WHEN hvc.cd_gender = 'M' THEN 'Mr. ' || c.c_last_name
        ELSE 'Ms. ' || c.c_last_name
    END AS full_name,
    COALESCE(rp.total_returned, 0) AS total_returns,
    COALESCE(rs.total_sales, 0) AS sales_from_high_value_histories
FROM 
    customer c
JOIN 
    HighValueCustomers hvc ON c.c_customer_sk = hvc.c_customer_sk
LEFT JOIN (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.wr_return_amt) AS total_returned
    FROM 
        web_returns wr
    GROUP BY 
        wr.refunded_customer_sk
) rp ON c.c_customer_sk = rp.refunded_customer_sk
LEFT JOIN (
    SELECT 
        ws_promo_sk,
        SUM(ws.net_paid) AS total_sales
    FROM 
        web_sales ws
    INNER JOIN 
        RankedSales rs ON ws.ws_item_sk = rs.ws_item_sk
    WHERE 
        rs.sales_rank <= 10
    GROUP BY 
        ws.ws_promo_sk
) rs ON rs.ws_promo_sk = hvc.total_orders
WHERE 
    (hvc.customer_type = 'VIP' OR hvc.customer_type = 'Valuable')
ORDER BY 
    hvc.total_profit DESC, c.c_last_name ASC;
