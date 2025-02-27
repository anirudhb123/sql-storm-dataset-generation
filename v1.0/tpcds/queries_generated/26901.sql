
WITH address_summary AS (
    SELECT 
        CA.ca_country,
        COUNT(DISTINCT C.c_customer_sk) AS customer_count,
        AVG(CD.cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT CONCAT(CA.ca_street_number, ' ', CA.ca_street_name, ' ', CA.ca_street_type), ', ') AS street_addresses
    FROM 
        customer_address CA
    JOIN 
        customer C ON CA.ca_address_sk = C.c_current_addr_sk
    JOIN 
        customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
    GROUP BY 
        CA.ca_country
),
date_aggregation AS (
    SELECT 
        D.d_year,
        D.d_month_seq,
        AVG(WS.ws_net_profit) AS avg_net_profit,
        STRING_AGG(DISTINCT D.d_day_name, ', ') AS included_days
    FROM 
        web_sales WS
    JOIN 
        date_dim D ON WS.ws_sold_date_sk = D.d_date_sk
    GROUP BY 
        D.d_year, D.d_month_seq
)
SELECT 
    AS.ca_country,
    AS.customer_count,
    AS.avg_purchase_estimate,
    AS.street_addresses,
    DA.d_year,
    DA.d_month_seq,
    DA.avg_net_profit,
    DA.included_days
FROM 
    address_summary AS
JOIN 
    date_aggregation DA ON 1=1
WHERE 
    AS.customer_count > 100
ORDER BY 
    AS.customer_count DESC, DA.avg_net_profit DESC;
