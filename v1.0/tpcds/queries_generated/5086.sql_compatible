
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_sales_price - ws.ws_coupon_amt) AS net_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws.ws_item_sk, i.i_item_desc
), customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.net_sales) AS customer_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_data sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(cd.c_customer_sk) AS customer_count,
    SUM(cd.customer_sales) AS total_customer_sales,
    AVG(cd.customer_sales) AS avg_customer_sales
FROM 
    customer_data cd
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_customer_sales DESC;
