
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
return_summary AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_returned_amount,
        SUM(wr.wr_return_tax) AS total_returned_tax
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk IS NOT NULL
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    ss.total_quantity,
    ss.total_sales,
    ss.total_profit,
    rs.total_returns,
    rs.total_returned_amount,
    rs.total_returned_tax
FROM 
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_sk IN (
        SELECT 
            ws.ws_bill_customer_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_item_sk = ss.ws_item_sk
    )
LEFT JOIN 
    return_summary rs ON ss.ws_item_sk = rs.wr_item_sk
WHERE 
    cs.cd_purchase_estimate BETWEEN 1000 AND 5000
    AND (cs.cd_gender = 'F' OR cs.cd_marital_status = 'M')
ORDER BY 
    ss.total_sales DESC,
    cs.c_last_name ASC
LIMIT 50;
