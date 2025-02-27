
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_ticket_number,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) as rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
HighValueItems AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_current_price,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        item
    JOIN 
        web_sales ON i_item_sk = ws_item_sk
    GROUP BY 
        i_item_sk, i_item_id, i_current_price
    HAVING 
        SUM(ws_ext_sales_price) > 1000
),
EligibleCustomers AS (
    SELECT
        c_customer_sk,
        COUNT(DISTINCT sr_item_sk) AS return_count
    FROM 
        customer
    LEFT OUTER JOIN 
        store_returns ON c_customer_sk = sr_customer_sk
    WHERE 
        c_birth_year IS NOT NULL AND c_birth_month IS NOT NULL
    GROUP BY 
        c_customer_sk
    HAVING 
        return_count > 5
),
FinalResults AS (
    SELECT 
        ca.city AS address_city,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        MAX(ws.ws_net_paid) AS max_net_paid
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        HighValueItems hvi ON ws.ws_item_sk = hvi.i_item_sk
    LEFT JOIN 
        RankedReturns rr ON hvi.i_item_sk = rr.sr_item_sk
    LEFT JOIN 
        EligibleCustomers ec ON c.c_customer_sk = ec.c_customer_sk
    WHERE 
        (cd.cd_gender = 'F' AND ec.c_customer_sk IS NOT NULL) OR
        (cd.cd_gender IS NULL AND ec.c_customer_sk IS NULL)
    GROUP BY 
        ca.city, cd.cd_gender
)

SELECT 
    address_city,
    cd_gender,
    total_orders,
    total_net_profit,
    max_net_paid
FROM 
    FinalResults
WHERE 
    (total_orders > 10 OR total_net_profit > 500)
ORDER BY 
    address_city DESC, total_net_profit ASC;
