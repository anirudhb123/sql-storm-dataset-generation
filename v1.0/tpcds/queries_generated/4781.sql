
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) as rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer_address
    INNER JOIN customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_state
),
HighValueSales AS (
    SELECT 
        item.i_item_id,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        RankedSales RS
    JOIN 
        item ON RS.ws_item_sk = item.i_item_sk
    WHERE 
        RS.rank = 1
    GROUP BY 
        item.i_item_id
    HAVING 
        SUM(ws_net_paid) > 1000
)
SELECT 
    A.ca_state,
    COALESCE(HV.total_net_paid, 0) AS high_value_sales,
    AC.customer_count
FROM 
    AddressCounts AC
LEFT JOIN 
    HighValueSales HV ON HV.i_item_id = (SELECT i_item_id FROM item ORDER BY RANDOM() LIMIT 1)
JOIN 
    customer_address A ON AC.ca_state = A.ca_state
WHERE 
    AC.customer_count > 5
ORDER BY 
    AC.customer_count DESC, high_value_sales DESC;
