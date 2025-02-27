
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        d.d_month_seq,
        c.c_birth_year,
        p.p_channel_email,
        p.p_channel_tv
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2021 AND 2023 
    GROUP BY 
        ws.ws_order_number, 
        ws.ws_sold_date_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        d.d_year, 
        d.d_month_seq, 
        c.c_birth_year,
        p.p_channel_email, 
        p.p_channel_tv
),
AggregateData AS (
    SELECT 
        d_year,
        d_month_seq,
        cd_gender,
        cd_marital_status,
        SUM(total_quantity) AS grand_total_quantity,
        SUM(total_sales) AS grand_total_sales,
        SUM(total_discount) AS grand_total_discount,
        SUM(total_tax) AS grand_total_tax
    FROM SalesData
    GROUP BY 
        d_year, 
        d_month_seq,
        cd_gender, 
        cd_marital_status
)
SELECT 
    ad.d_year, 
    ad.d_month_seq,
    ad.cd_gender, 
    ad.cd_marital_status,
    ad.grand_total_quantity,
    ad.grand_total_sales,
    ad.grand_total_discount,
    ad.grand_total_tax,
    COUNT(DISTINCT(ws_order_number)) AS total_orders,
    AVG(CASE WHEN ad.grand_total_sales > 0 THEN (ad.grand_total_sales / NULLIF(ad.grand_total_quantity, 0)) ELSE 0 END) AS avg_sales_per_item
FROM AggregateData ad
GROUP BY 
    ad.d_year, 
    ad.d_month_seq,
    ad.cd_gender, 
    ad.cd_marital_status
ORDER BY ad.d_year, ad.d_month_seq, ad.cd_gender, ad.cd_marital_status;
