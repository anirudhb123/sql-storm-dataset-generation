
WITH RECURSIVE sales_data AS (
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_sales,
        SUM(s.ss_ext_sales_price) AS total_sales_amount,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_quantity) DESC) AS sales_rank
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk >= (
            SELECT MIN(d.d_date_sk)
            FROM date_dim d
            WHERE d.d_year = 2023
        )
    GROUP BY 
        s.ss_sold_date_sk, s.ss_item_sk
),
top_sales AS (
    SELECT 
        sd.ss_item_sk, 
        sd.total_sales, 
        sd.total_sales_amount
    FROM 
        sales_data sd
    WHERE 
        sd.sales_rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
return_data AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ts.total_sales,
    ts.total_sales_amount,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    ci.cd_gender,
    ci.cd_marital_status
FROM 
    item i
LEFT JOIN 
    top_sales ts ON i.i_item_sk = ts.ss_item_sk
LEFT JOIN 
    return_data rd ON i.i_item_sk = rd.sr_item_sk
JOIN 
    customer_info ci ON ci.cd_purchase_estimate > 500
WHERE 
    i.i_current_price > 20.00
ORDER BY 
    ts.total_sales DESC, ts.total_sales_amount DESC NULLS LAST;
