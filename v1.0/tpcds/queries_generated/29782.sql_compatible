
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        a.full_address,
        a.ca_city,
        a.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT 
        w.web_site_id, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_open_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        w.web_site_id
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.full_address,
    ci.ca_city,
    ci.ca_state,
    sd.web_site_id,
    sd.total_net_profit,
    sd.total_orders
FROM 
    CustomerInfo ci
JOIN 
    SalesData sd ON ci.c_customer_id = (
        SELECT 
            CASE 
                WHEN COUNT(*) = 1 THEN c.c_customer_id 
                ELSE NULL 
            END
        FROM 
            customer c
        WHERE 
            c.c_customer_sk IN (
                SELECT 
                    DISTINCT ws.ws_bill_customer_sk
                FROM 
                    web_sales ws
                WHERE 
                    ws.ws_web_site_sk IN (
                        SELECT 
                            w.web_site_sk
                        FROM 
                            web_site w
                    )
            )
    )
WHERE 
    sd.total_net_profit > 1000
ORDER BY 
    sd.total_net_profit DESC, 
    ci.full_name;
