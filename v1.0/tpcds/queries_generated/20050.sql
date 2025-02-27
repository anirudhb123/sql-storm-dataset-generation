
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        sr_return_quantity, 
        sr_return_amt, 
        sr_return_date_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_amt DESC) AS rnk
    FROM 
        store_returns
),
CustomerPurchaseInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_preferred_cust_flag
),
ItemSummary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ss_quantity) AS total_sold,
        AVG(ss_sales_price) AS average_price
    FROM 
        item i
    JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
)

SELECT 
    ca.ca_address_sk,
    ca.ca_city,
    ci.c_customer_sk,
    ci.total_spent,
    ci.order_count,
    it.i_item_desc,
    rt.sr_return_quantity,
    rt.sr_return_amt,
    COALESCE(rt.sr_return_quantity / NULLIF(it.total_sold, 0), 0) AS return_rate,
    (SELECT COUNT(*) 
     FROM CustomerPurchaseInfo
     WHERE total_spent > 100 ) AS high_value_customer_count
FROM 
    customer_address ca
LEFT JOIN CustomerPurchaseInfo ci ON ca.ca_address_sk = ci.c_customer_sk
JOIN ItemSummary it ON it.i_item_sk = (
    SELECT sr_item_sk
    FROM RankedReturns
    WHERE rnk = 1 AND sr_return_date_sk = (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_date <= '2023-10-01'
    )
)
JOIN RankedReturns rt ON it.i_item_sk = rt.sr_item_sk 
WHERE 
    cca.ca_city IS NOT NULL 
    AND (ci.total_spent > 500 OR ci.c_preferred_cust_flag = 'Y')

UNION ALL

SELECT 
    ca.ca_address_sk,
    ca.ca_city,
    NULL AS c_customer_sk,
    NULL AS total_spent,
    NULL AS order_count,
    it.i_item_desc,
    NULL AS sr_return_quantity,
    NULL AS sr_return_amt,
    NULL AS return_rate,
    (SELECT COUNT(*)
     FROM CustomerPurchaseInfo
     WHERE order_count = 0) AS high_value_customer_count
FROM 
    customer_address ca
JOIN ItemSummary it ON it.i_item_sk NOT IN (
    SELECT rt.sr_item_sk
    FROM RankedReturns rt
    WHERE rt.rnk = 1
)
WHERE 
    ca.ca_state IN ('CA', 'NY') 
    AND (EXISTS (SELECT 1 FROM customer c WHERE c.c_birth_month = 10)
    OR EXISTS (SELECT 1 FROM date_dim dd WHERE dd.d_current_year = 2023));

