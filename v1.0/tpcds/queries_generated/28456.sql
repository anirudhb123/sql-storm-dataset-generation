
WITH filtered_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY') 
        AND cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
),
sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_order_number,
        DATE_FORMAT(dd.d_date, '%Y-%m') AS sale_month
    FROM 
        web_sales ws
        JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
        JOIN filtered_customers fc ON ws.ws_bill_customer_sk = fc.c_customer_sk
),
aggregation AS (
    SELECT 
        sd.sale_month,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        COUNT(DISTINCT sd.ws_order_number) AS order_count,
        COUNT(DISTINCT fc.c_customer_sk) AS unique_customers
    FROM 
        sales_data sd
        JOIN filtered_customers fc ON sd.ws_item_sk = fc.c_customer_sk
    GROUP BY 
        sd.sale_month
)
SELECT 
    ag.sale_month,
    ag.total_sales,
    ag.order_count,
    ag.unique_customers
FROM 
    aggregation ag
ORDER BY 
    ag.sale_month DESC;
