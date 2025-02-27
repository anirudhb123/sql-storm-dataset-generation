
WITH Sales_Data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        C.c_first_name,
        C.c_last_name,
        A.ca_city,
        A.ca_state,
        SM.sm_type,
        D.d_year,
        (CASE 
            WHEN C.c_birth_month IS NULL THEN 'Unknown'
            ELSE CONCAT(MONTHNAME(STR_TO_DATE(CONCAT(C.c_birth_month, ' 1, ', C.c_birth_year), '%m %d, %Y')), ' ', C.c_birth_year)
        END) AS birth_date
    FROM 
        web_sales ws
    JOIN 
        customer C ON ws.ws_bill_customer_sk = C.c_customer_sk
    JOIN 
        customer_address A ON C.c_current_addr_sk = A.ca_address_sk
    JOIN 
        ship_mode SM ON ws.ws_ship_mode_sk = SM.sm_ship_mode_sk
    JOIN 
        date_dim D ON ws.ws_sold_date_sk = D.d_date_sk
    WHERE 
        D.d_year BETWEEN 2020 AND 2023
),
Ranked_Sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        profit_rank,
        c_first_name,
        c_last_name,
        ca_city,
        ca_state,
        sm_type,
        d_year,
        birth_date
    FROM 
        Sales_Data
)
SELECT 
    R.ws_item_sk,
    R.ws_order_number,
    R.ws_quantity,
    R.ws_net_profit,
    R.c_first_name,
    R.c_last_name,
    R.ca_city,
    R.ca_state,
    R.sm_type,
    R.d_year,
    R.birth_date
FROM 
    Ranked_Sales R
WHERE 
    R.profit_rank <= 10
ORDER BY 
    R.d_year DESC, R.ws_net_profit DESC
UNION ALL
SELECT 
    I.i_item_sk,
    NULL AS ws_order_number,
    NULL AS ws_quantity,
    NULL AS ws_net_profit,
    NULL AS c_first_name,
    NULL AS c_last_name,
    NULL AS ca_city,
    NULL AS ca_state,
    NULL AS sm_type,
    NULL AS d_year,
    NULL AS birth_date
FROM 
    item I
WHERE 
    I.i_current_price IS NULL
ORDER BY 
    d_year DESC, ws_net_profit DESC;
