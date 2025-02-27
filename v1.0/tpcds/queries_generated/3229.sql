
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_net_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM
        CustomerSales cs
    JOIN customer c ON c.c_customer_sk = cs.c_customer_sk
),
PromotionalSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_net_profit) AS promo_sales_profit
    FROM
        web_sales ws
    JOIN promotion p ON p.p_promo_sk = ws.ws_promo_sk
    WHERE
        p.p_discount_active = 'Y'
    GROUP BY
        ws.ws_item_sk, ws.ws_order_number
),
SalesComparison AS (
    SELECT
        s.ss_item_sk,
        SUM(s.ss_net_profit) AS store_net_profit,
        COALESCE(ps.promo_sales_profit, 0) AS promo_net_profit
    FROM
        store_sales s
    LEFT JOIN PromotionalSales ps ON s.ss_item_sk = ps.ws_item_sk
    GROUP BY
        s.ss_item_sk
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit AS customer_profit,
    sc.store_net_profit,
    sc.promo_net_profit,
    sc.store_net_profit - sc.promo_net_profit AS difference
FROM
    TopCustomers tc
JOIN SalesComparison sc ON tc.c_customer_sk = sc.ss_item_sk
WHERE
    tc.rank <= 10
ORDER BY
    tc.total_net_profit DESC, sc.store_net_profit DESC;
