
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        d.d_year,
        d.d_quarter_seq,
        i.i_item_desc,
        i.i_brand,
        c.cd_gender,
        c.cd_marital_status,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_quarter_seq, i.i_item_desc, i.i_brand, c.cd_gender, c.cd_marital_status, ca.ca_state
), 
Demographics AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count
    FROM 
        customer_demographics
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk
)
SELECT 
    sd.i_item_desc,
    sd.i_brand,
    sd.total_quantity,
    sd.total_net_paid,
    sd.total_sales,
    d.customer_count,
    d.married_count,
    d.female_count,
    d.male_count,
    sd.d_year,
    sd.d_quarter_seq,
    sd.ca_state
FROM 
    SalesData sd
JOIN 
    Demographics d ON sd.cd_gender = d.cd_gender
ORDER BY 
    sd.total_sales DESC, sd.total_quantity DESC
LIMIT 100;
