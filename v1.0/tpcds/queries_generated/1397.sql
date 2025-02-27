
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighSalesItems AS (
    SELECT 
        r.ws_item_sk, 
        i.i_item_desc, 
        i.i_brand, 
        i.i_color 
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.sales_rank <= 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        d.d_date, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_date
),
AggregateSales AS (
    SELECT 
        hsi.ws_item_sk,
        ci.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_coupon_amt) AS total_coupons
    FROM 
        HighSalesItems hsi
    JOIN 
        web_sales ws ON hsi.ws_item_sk = ws.ws_item_sk
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_id
    GROUP BY 
        hsi.ws_item_sk, ci.c_customer_id
)
SELECT 
    hsi.i_item_desc, 
    hsi.i_brand, 
    hsi.i_color,
    ci.c_first_name, 
    ci.c_last_name, 
    ag.total_sales,
    ag.total_coupons,
    (CASE 
        WHEN ag.total_sales IS NULL THEN 0 
        ELSE ag.total_sales - COALESCE(ag.total_coupons, 0) 
     END) AS net_sales
FROM 
    HighSalesItems hsi
JOIN 
    AggregateSales ag ON hsi.ws_item_sk = ag.ws_item_sk
JOIN 
    customer_info ci ON ag.c_customer_id = ci.c_customer_id
WHERE 
    ag.total_sales > 1000
ORDER BY 
    net_sales DESC;
