
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) as total_quantity,
        SUM(ws_ext_sales_price) as total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) as sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk = (
        SELECT MAX(ws_sold_date_sk) 
        FROM web_sales
        WHERE ws_item_sk IS NOT NULL
    )
    GROUP BY ws_item_sk, ws_order_number
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') as gender,
        SUM(CASE WHEN ws.net_paid > 100 THEN 1 ELSE 0 END) as high_value_orders,
        COUNT(DISTINCT ws.ws_order_number) as total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.gender,
        cs.total_orders,
        cs.high_value_orders,
        ROW_NUMBER() OVER (PARTITION BY cs.gender ORDER BY cs.high_value_orders DESC) as rank_by_high_value
    FROM CustomerStats cs
    WHERE (cs.total_orders > 0 OR cs.high_value_orders > 0)
),
SalesPromotions AS (
    SELECT 
        p.p_promo_id,
        COUNT(ws.ws_order_number) as promo_sales_count
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id
),
FinalSelection AS (
    SELECT 
        rc.ws_item_sk,
        rc.total_quantity,
        rc.total_sales,
        tc.c_customer_sk,
        tc.gender
    FROM RankedSales rc
    JOIN TopCustomers tc ON rc.ws_order_number = (SELECT MIN(rank_by_high_value)
                                                  FROM TopCustomers
                                                  WHERE gender = tc.gender)
)

SELECT 
    fs.ws_item_sk,
    fs.total_quantity,
    fs.total_sales,
    tc.gender,
    CASE 
        WHEN fs.total_sales > (SELECT AVG(total_sales) FROM RankedSales) THEN 'Above Average'
        ELSE 'Below Average'
    END as sales_performance,
    (SELECT COUNT(*) FROM SalesPromotions sp WHERE sp.promo_sales_count > 5) as active_promotions
FROM FinalSelection fs
JOIN TopCustomers tc ON fs.c_customer_sk = tc.c_customer_sk
WHERE fs.total_quantity BETWEEN (
      SELECT MIN(total_quantity) FROM RankedSales
) AND (
      SELECT MAX(total_quantity) FROM RankedSales
)
ORDER BY fs.total_sales DESC, fs.total_quantity DESC;
