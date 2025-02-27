
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws_bill_customer_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_demographics_sk,
        ca.ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
ReturnSummary AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) as total_return_amt,
        COUNT(sr_ticket_number) as total_returns
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        sr_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ss.total_net_paid,
    rs.total_return_amt,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(rs.total_returns, 0) AS total_returns,
    CASE 
        WHEN ss.total_net_paid IS NULL 
        THEN 'No Sales' 
        ELSE 'Active'
    END AS customer_status,
    CASE 
        WHEN cd.ca_state IS NULL THEN 'Unknown'
        ELSE cd.ca_state
    END AS state
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    ReturnSummary rs ON cd.c_customer_sk = rs.sr_customer_sk
WHERE 
    cd.cd_income_band_sk IN (
        SELECT ib_income_band_sk 
        FROM income_band 
        WHERE ib_lower_bound < 50000 AND ib_upper_bound >= 50000
    )
ORDER BY 
    total_net_paid DESC NULLS LAST
LIMIT 100;
