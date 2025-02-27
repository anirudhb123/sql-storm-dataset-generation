
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
TopReturningCustomers AS (
    SELECT 
        r.returning_customer_sk,
        r.total_returns,
        r.total_return_amt
    FROM 
        RankedReturns r
    WHERE 
        r.rn <= 5
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_net_paid) AS max_net_paid
    FROM 
        web_sales ws
    WHERE 
        EXISTS (
            SELECT 1
            FROM store_sales ss
            WHERE ss.ss_item_sk = ws.ws_item_sk
            AND ss.ss_sold_date_sk IN (
                SELECT d.d_date_sk
                FROM date_dim d
                WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 3
            )
        )
    GROUP BY 
        ws.ws_ship_customer_sk
)
SELECT 
    CONCAT(cd.c_first_name, ' ', cd.c_last_name) AS customer_name,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    COALESCE(trc.total_returns, 0) AS total_returns,
    COALESCE(trc.total_return_amt, 0) AS total_return_amt,
    sd.total_profit,
    sd.avg_sales_price,
    sd.max_net_paid
FROM 
    CustomerDetails cd
LEFT JOIN 
    TopReturningCustomers trc ON cd.c_customer_sk = trc.returning_customer_sk
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_ship_customer_sk
WHERE 
    cd.ca_city IS NOT NULL 
    AND cd.ca_state IS NOT NULL 
    AND (trc.total_returns IS NULL OR trc.total_return_amt > 100)
ORDER BY 
    total_returns DESC NULLS LAST, 
    sd.total_profit DESC NULLS LAST;
