
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sales_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk, ws.ws_net_paid DESC) AS sales_row_number
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
),
AggregatedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FilteredDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown Rating' 
            ELSE cd.cd_credit_rating 
        END AS credit_rating, 
        CASE 
            WHEN cd.cd_dep_count > 2 THEN 'Large Family' 
            WHEN cd.cd_dep_count = 2 THEN 'Medium Family' 
            ELSE 'Small Family' 
        END AS family_size 
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate > 1000 
        OR (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M')
),
JoinResults AS (
    SELECT 
        ca.ca_address_id,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        COALESCE(a.total_returned, 0) AS total_returns,
        COALESCE(a.total_return_amount, 0) AS total_returns_amount,
        rd.family_size,
        COUNT(DISTINCT w.ws_order_number) AS web_sales_count,
        SUM(w.ws_net_profit) AS total_web_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    LEFT JOIN 
        AggregatedReturns a ON c.c_customer_sk = a.sr_customer_sk
    JOIN 
        FilteredDemographics rd ON c.c_current_cdemo_sk = rd.cd_demo_sk
    LEFT JOIN 
        web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    WHERE 
        d.d_year = 2023 
        AND (ca.ca_city = 'New York' OR ca.ca_city IS NULL)
    GROUP BY 
        ca.ca_address_id, c.c_customer_id, c.c_first_name, c.c_last_name, d.d_date, a.total_returned, a.total_return_amount, rd.family_size
)
SELECT 
    j.ca_address_id,
    j.c_customer_id,
    j.c_first_name,
    j.c_last_name,
    j.d_date,
    j.total_returns,
    j.total_returns_amount,
    j.family_size,
    RANK() OVER (PARTITION BY j.family_size ORDER BY j.total_web_profit DESC) AS profit_rank
FROM 
    JoinResults j
WHERE 
    j.total_returns > (SELECT AVG(total_returned) FROM AggregatedReturns)
ORDER BY 
    j.family_size, j.total_web_profit DESC, j.d_date DESC;
