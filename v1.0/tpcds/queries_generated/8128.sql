
WITH SalesData AS (
    SELECT 
        ws.ws_web_page_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
),
AggregatedSales AS (
    SELECT 
        ws_web_page_sk,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_net_sales_price) AS avg_sales_price,
        cd_gender,
        cd_marital_status,
        ca_state
    FROM SalesData
    GROUP BY ws_web_page_sk, cd_gender, cd_marital_status, ca_state
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_quantity DESC) AS rank_by_quantity
    FROM AggregatedSales
)
SELECT 
    ws_web_page_sk,
    total_quantity,
    avg_sales_price,
    cd_gender,
    cd_marital_status,
    ca_state
FROM RankedSales
WHERE rank_by_quantity <= 10
ORDER BY ca_state, total_quantity DESC;
