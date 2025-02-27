
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ci.ca_city,
        cc.cc_mkt_desc,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        call_center cc ON c.c_current_hdemo_sk = cc.cc_call_center_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        d.d_year = 2022
        AND ca.ca_city IN (SELECT ca_city FROM customer_address WHERE ca_state = 'CA')
        AND i.i_current_price > 100
),
AggregatedSales AS (
    SELECT 
        sd.ca_city,
        COUNT(DISTINCT sd.ws_order_number) AS total_orders,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_net_profit,
        sd.d_year
    FROM 
        SalesData sd
    GROUP BY 
        sd.ca_city, sd.d_year
),
RankedSales AS (
    SELECT 
        as.ca_city,
        as.total_orders,
        as.total_quantity,
        as.total_net_profit,
        RANK() OVER (PARTITION BY as.d_year ORDER BY as.total_net_profit DESC) AS profit_rank
    FROM 
        AggregatedSales as
)
SELECT 
    rs.ca_city,
    rs.total_orders,
    rs.total_quantity,
    rs.total_net_profit
FROM 
    RankedSales rs
WHERE 
    rs.profit_rank <= 10
ORDER BY 
    rs.total_net_profit DESC;
