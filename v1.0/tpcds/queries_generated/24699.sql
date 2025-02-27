
WITH RankedReturns AS (
    SELECT
        sr_returning_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM
        store_returns
),
HighValueReturns AS (
    SELECT
        r.returning_customer_sk,
        SUM(r.return_quantity) AS total_returned,
        COUNT(r.returning_customer_sk) AS total_returns,
        CASE 
            WHEN SUM(r.return_quantity) > 100 THEN 'High'
            WHEN SUM(r.return_quantity) BETWEEN 51 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS return_category
    FROM 
        RankedReturns r
    WHERE
        r.rn <= 3
    GROUP BY
        r.returning_customer_sk
),
CustomerShippingDetails AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        COALESCE(d.d_month_seq, 0) AS month_seq,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        SUM(ws.ws_quantity) AS total_items
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        c.c_customer_sk, ca.ca_city, ca.ca_state, d.d_month_seq
),
FinalReport AS (
    SELECT
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.total_items,
        hvr.return_category
    FROM
        CustomerShippingDetails cs
    LEFT JOIN HighValueReturns hvr ON cs.c_customer_sk = hvr.returning_customer_sk
    WHERE
        (cs.total_spent IS NOT NULL AND cs.total_spent > 500) OR
        (cs.total_orders IS NULL AND hvr.return_category IS NOT NULL)
)
SELECT
    f.c_customer_sk,
    f.total_orders,
    f.total_spent,
    f.total_items,
    COALESCE(f.return_category, 'No Returns') AS return_category,
    CASE 
        WHEN f.total_spent > 1000 THEN 'VIP'
        WHEN f.total_spent BETWEEN 500 AND 1000 THEN 'Regular'
        ELSE 'New Customer'
    END AS customer_level
FROM
    FinalReport f
ORDER BY
    f.total_spent DESC, f.total_orders ASC
LIMIT 1000;
