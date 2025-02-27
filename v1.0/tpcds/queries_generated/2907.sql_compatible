
WITH SalesData AS (
    SELECT 
        ws_order_number, 
        ws_quantity, 
        ws_net_profit, 
        ws_bill_cdemo_sk,
        DENSE_RANK() OVER (PARTITION BY ws_bill_cdemo_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM web_sales
    WHERE ws_ship_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
),
TopCustomers AS (
    SELECT 
        cd_demo_sk, 
        SUM(ws_net_profit) AS total_profit
    FROM SalesData
    JOIN customer_demographics ON SalesData.ws_bill_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY cd_demo_sk
    HAVING SUM(ws_net_profit) > (SELECT AVG(total_profit) FROM (SELECT SUM(ws_net_profit) AS total_profit 
                                                                FROM SalesData 
                                                                GROUP BY ws_bill_cdemo_sk) AS avg_profit)
),
CustomerAddress AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY')
),
ReturnData AS (
    SELECT 
        wr_returned_date_sk, 
        wr_return_time_sk, 
        wr_item_sk, 
        wr_return_quantity,
        SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM web_returns
    WHERE wr_returned_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_current_year = 'Y' AND d_moy = 1)
    GROUP BY wr_returned_date_sk, wr_return_time_sk, wr_item_sk, wr_return_quantity
),
FinalReport AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        SUM(sd.ws_net_profit) AS total_sales,
        COALESCE(SUM(rd.total_return_value), 0) AS total_returns,
        (SUM(sd.ws_net_profit) - COALESCE(SUM(rd.total_return_value), 0)) AS net_revenue
    FROM customer c
    JOIN TopCustomers tc ON c.c_current_cdemo_sk = tc.cd_demo_sk
    JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN CustomerAddress ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN ReturnData rd ON rd.wr_refunded_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, ca.ca_city
)
SELECT 
    f.c_customer_id,
    f.ca_city,
    f.total_sales,
    f.total_returns,
    f.net_revenue
FROM FinalReport f
WHERE f.net_revenue > 1000
ORDER BY f.net_revenue DESC;
