
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_sold_date_sk,
        ws.ws_quantity, 
        ws.ws_net_paid_inc_tax, 
        cust.c_customer_id,
        cust.c_first_name || ' ' || cust.c_last_name AS full_name,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer cust ON ws.ws_bill_customer_sk = cust.c_customer_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
MostRecentSales AS (
    SELECT 
        sd.*, 
        DENSE_RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.ws_sold_date_sk DESC) AS recent_rank
    FROM 
        SalesData sd
)
SELECT 
    sr.customers_ordered,
    wrn.returned_items,
    max_sales.max_sales_price,
    wrn.total_return_amount
FROM 
    (SELECT 
        COUNT(DISTINCT c_customer_id) AS customers_ordered, 
        SUM(ws.ws_quantity) AS total_sold 
     FROM 
        web_sales ws 
     JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
     GROUP BY 
        c.c_customer_sk) sr
FULL OUTER JOIN 
    (SELECT 
        wrn.ws_item_sk, 
        SUM(wr.wr_return_amt) AS total_return_amount
     FROM 
        web_returns wr 
     JOIN 
        web_sales wrn ON wrn.ws_order_number = wr.wr_order_number
     GROUP BY 
        wrn.ws_item_sk) wrn
ON wrn.ws_item_sk = sr.customers_ordered
CROSS JOIN 
    (SELECT 
        sd.ws_item_sk,
        MAX(sd.ws_net_paid_inc_tax) AS max_sales_price
     FROM 
        SalesData sd 
     WHERE 
        sd.rn = 1
     GROUP BY 
        sd.ws_item_sk) max_sales
WHERE 
    EXISTS (SELECT 1 
            FROM MostRecentSales 
            WHERE recent_rank = 1 AND ws_item_sk = max_sales.ws_item_sk)
ORDER BY 
    sr.customers_ordered DESC, wrn.total_return_amount DESC;
