
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(sr.ticket_number) AS total_returns,
        SUM(sr.return_amt_inc_tax) AS total_returned_amt,
        COUNT(DISTINCT sr.store_sk) AS stores_returned_from
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE 
        sr.returned_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND sr.returned_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
PopularItems AS (
    SELECT 
        ws.ws_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk, i.i_item_id, i.i_product_name
    HAVING 
        SUM(ws.ws_quantity) > 1000
),
FinalReport AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        pi.i_item_id,
        pi.i_product_name,
        pi.total_sold,
        pi.total_revenue,
        cs.total_returns,
        cs.total_returned_amt,
        cs.stores_returned_from
    FROM 
        CustomerStats cs
    JOIN 
        PopularItems pi ON cs.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = pi.ws_item_sk LIMIT 1)
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.total_returned_amt > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    FinalReport fr
ORDER BY 
    total_revenue DESC;
