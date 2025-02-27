
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        DATE_FORMAT(CONCAT(d.d_year, '-', d.d_moy, '-', d.d_dom), '%Y-%m-%d') AS Purchase_Date
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        (SELECT d_date_sk, d_year, d_moy, d_dom FROM date_dim WHERE d_date BETWEEN '2022-01-01' AND '2022-12-31') d ON c.c_first_sales_date_sk = d.d_date_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    sd.total_quantity_sold,
    sd.total_sales_amount,
    sd.total_orders,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    item i
JOIN 
    SalesData sd ON i.i_item_sk = sd.ws_item_sk
JOIN 
    income_band ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    sd.total_sales_amount > 1000
ORDER BY 
    sd.total_sales_amount DESC
LIMIT 10;
