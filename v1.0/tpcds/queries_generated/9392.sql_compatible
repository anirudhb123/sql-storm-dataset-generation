
WITH SalesData AS (
    SELECT 
        ws.ws_web_page_sk, 
        ws.ws_item_sk, 
        ws.ws_quantity, 
        ws.ws_sales_price, 
        ws.ws_net_paid,
        ws.ws_net_profit,
        d.d_year,
        c.c_gender,
        ca.ca_state
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
),
AggregatedData AS (
    SELECT 
        sd.ws_web_page_sk, 
        sd.ca_state,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_sales,
        SUM(sd.ws_net_profit) AS total_profit
    FROM SalesData sd
    GROUP BY sd.ws_web_page_sk, sd.ca_state
),
RankedData AS (
    SELECT 
        ad.ws_web_page_sk, 
        ad.ca_state,
        ad.total_quantity,
        ad.total_sales,
        ad.total_profit,
        RANK() OVER (PARTITION BY ad.ca_state ORDER BY ad.total_sales DESC) AS sales_rank
    FROM AggregatedData ad
)
SELECT 
    r.ws_web_page_sk, 
    r.ca_state, 
    r.total_quantity, 
    r.total_sales, 
    r.total_profit
FROM RankedData r
WHERE r.sales_rank <= 5
ORDER BY r.ca_state, r.total_sales DESC;
