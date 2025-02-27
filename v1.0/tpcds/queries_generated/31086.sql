
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 2458470 -- Filtering for a specific date range
),
TopSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        SalesCTE
    WHERE 
        rank <= 10
    GROUP BY
        ws_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.net_paid), 0) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        SUM(ts.total_profit) AS city_total_profit
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        TopSales ts ON ts.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    s.ws_sold_date_sk,
    p.p_promo_name,
    wd.wd_website_id,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers,
    SUM(ts.total_profit) AS total_profit_per_promotion,
    AVG(cd.total_spent) AS avg_spent_per_customer,
    STRING_AGG(DISTINCT ca.ca_city || ', ' || ca.ca_state) AS customer_locations
FROM 
    TopSales ts
JOIN 
    promotion p ON ts.ws_item_sk = p.p_item_sk
JOIN 
    web_site ws ON ws.web_site_sk = (SELECT web_site_sk FROM web_sales WHERE ws_item_sk = ts.ws_item_sk LIMIT 1)
JOIN 
    CustomerDetails cd ON ts.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = cd.c_customer_sk)
LEFT JOIN 
    AddressDetails ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = cd.c_customer_sk)
GROUP BY 
    s.ws_sold_date_sk, p.p_promo_name, wd.web_site_id
ORDER BY 
    total_profit_per_promotion DESC
LIMIT 50;
