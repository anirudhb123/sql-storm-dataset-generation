
WITH RecursiveSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MIN(d.d_date) AS first_purchase_date,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    JOIN 
        date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_sk
),
ItemStats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT r.r_reason_sk) AS return_count
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN 
        reason r ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
)
SELECT 
    cs.c_customer_sk,
    cs.total_spent,
    cs.order_count,
    it.i_item_desc,
    it.avg_net_profit,
    CASE 
        WHEN cs.total_spent > (SELECT AVG(total_spent) FROM CustomerPurchases) THEN 'High Roller'
        ELSE 'Regular'
    END AS customer_type,
    (SELECT SUM(total_spent) 
     FROM CustomerPurchases 
     WHERE first_purchase_date < (SELECT MAX(d.d_date) 
                                   FROM date_dim d 
                                   WHERE d.d_year = EXTRACT(YEAR FROM '2002-10-01'::DATE)) 
           AND last_purchase_date >= (SELECT MIN(d.d_date) 
                                       FROM date_dim d 
                                       WHERE d.d_year = EXTRACT(YEAR FROM '2002-10-01'::DATE) - 1)) AS special_coupon_amount
FROM 
    CustomerPurchases cs
JOIN 
    ItemStats it ON cs.c_customer_sk IN (SELECT sr_customer_sk FROM store_returns) 
WHERE 
    EXISTS (SELECT 1 FROM RecursiveSales rs WHERE rs.ws_item_sk = it.i_item_sk AND rs.rn = 1)
ORDER BY 
    cs.total_spent DESC, it.avg_net_profit DESC
LIMIT 10;
