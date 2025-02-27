
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
ReturnStats AS (
    SELECT 
        sr.returning_customer_sk,
        COUNT(DISTINCT sr.ticket_number) AS num_returns,
        SUM(sr.return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns sr
    WHERE 
        sr.store_sk IS NOT NULL 
    GROUP BY 
        sr.returning_customer_sk
),
TotalSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ca.ca_address_id, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_purchase_estimate,
    TS.total_spent,
    RS.total_returns,
    COALESCE(RS.total_returned_amount, 0) AS total_returned_amount,
    CASE 
        WHEN CD.cd_purchase_estimate > 1000 THEN 'High'
        WHEN CD.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS purchase_estimate_category
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    (SELECT 
        r.returning_customer_sk,
        COUNT(r.returning_customer_sk) AS total_returns
     FROM 
        store_returns r
     GROUP BY 
        r.returning_customer_sk) AS RS ON c.c_customer_sk = RS.returning_customer_sk
JOIN 
    TotalSales TS ON c.c_customer_sk = TS.customer_id
WHERE 
    (cd.cd_marital_status IS NULL OR cd.cd_marital_status = 'S')
    AND (ca.ca_state IN ('CA', 'NY', 'TX') OR ca.ca_city LIKE '%York%' OR ca.ca_country IS NULL)
    AND (cd.cd_purchase_estimate > 200 OR EXISTS (
        SELECT 1 FROM RankedSales RS WHERE RS.web_site_sk = c.c_current_hdemo_sk
        AND RS.sales_rank <= 5
    ))
ORDER BY 
    purchase_estimate_category, total_spent DESC;
