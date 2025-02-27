
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_quantity,
        rs.cd_gender,
        rs.cd_marital_status,
        rs.ca_city
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
),
AggregatedSales AS (
    SELECT 
        CD.cd_gender,
        CD.cd_marital_status,
        CA.ca_city,
        SUM(TS.ws_sales_price * TS.ws_quantity) AS total_sales
    FROM 
        TopSales TS
    JOIN 
        customer_demographics CD ON TS.cd_gender = CD.cd_gender AND TS.cd_marital_status = CD.cd_marital_status
    JOIN 
        customer_address CA ON TS.ca_city = CA.ca_city
    GROUP BY 
        CD.cd_gender, CD.cd_marital_status, CA.ca_city
)
SELECT 
    AS.cd_gender,
    AS.cd_marital_status,
    AS.ca_city,
    AVG(AS.total_sales) AS avg_total_sales
FROM 
    AggregatedSales AS
GROUP BY 
    AS.cd_gender, AS.cd_marital_status, AS.ca_city
ORDER BY 
    avg_total_sales DESC
LIMIT 50;
