
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COALESCE(ca.ca_state, 'Unknown') AS state,
        STRING_AGG(ca.ca_street_name, ', ') OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_street_name) AS street_names
    FROM 
        customer_address ca
),
HighIncomeCustomers AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    WHERE 
        hd.hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_upper_bound > 100000)
)
SELECT 
    ca.ca_city,
    ca.state,
    COUNT(DISTINCT cu.c_customer_sk) AS customer_count,
    SUM(CASE WHEN r.sales_rank = 1 THEN r.total_sales ELSE 0 END) AS top_sales,
    COUNT(DISTINCT hi.cd_demo_sk) AS high_income_count,
    (SELECT COUNT(*) FROM store s WHERE s.s_closed_date_sk IS NULL) AS operational_stores
FROM 
    CustomerAddress ca
JOIN 
    customer cu ON cu.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedSales r ON r.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = cu.c_customer_sk)
LEFT JOIN 
    HighIncomeCustomers hi ON hi.cd_demo_sk = cu.c_current_cdemo_sk
GROUP BY 
    ca.ca_city, ca.state
HAVING 
    COUNT(DISTINCT cu.c_customer_sk) > 5
ORDER BY 
    top_sales DESC, ca.ca_city ASC;
