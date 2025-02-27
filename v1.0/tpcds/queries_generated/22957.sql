
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk) AS total_net_paid
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
        AND ws.ws_sales_price > (SELECT AVG(ws_inner.ws_sales_price) FROM web_sales ws_inner WHERE ws_inner.ws_item_sk = ws.ws_item_sk)
        AND i.i_rec_start_date <= CURRENT_DATE
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
AddressedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_birth_month,
        ca.ca_city,
        ca.ca_state,
        RANK() OVER (PARTITION BY ca.ca_state ORDER BY c.c_birth_month) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
TopReturnReasons AS (
    SELECT 
        r.r_reason_desc,
        COUNT(sr.sr_return_quantity) AS total_returns,
        RANK() OVER (ORDER BY COUNT(sr.sr_return_quantity) DESC) AS return_rank
    FROM 
        store_returns sr
    JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY 
        r.r_reason_desc
)
SELECT 
    ac.c_customer_id,
    ac.ca_city,
    ac.ca_state,
    ac.customer_rank,
    COALESCE(rs.ws_sales_price, 0) AS highest_sales_price,
    tr.total_returns,
    tr.r_reason_desc
FROM 
    AddressedCustomers ac
FULL OUTER JOIN 
    RankedSales rs ON ac.c_customer_id = rs.ws_order_number 
FULL OUTER JOIN 
    TopReturnReasons tr ON ac.ca_state = 
        (SELECT MAX(ca_state) FROM customer_address WHERE ca_city = ac.ca_city)
WHERE 
    ac.customer_rank = 1 OR rs.sales_rank = 1
ORDER BY 
    ac.ca_state, 
    rs.highest_sales_price DESC,
    tr.total_returns DESC
LIMIT 
    100;
