
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws_order_number, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023 AND (d.d_dow IN (1, 2, 3) OR d.d_week_seq < 10)
    GROUP BY ws.web_site_sk, ws_order_number
), TopSales AS (
    SELECT 
        rs.web_site_sk, 
        rs.order_number, 
        rs.total_quantity, 
        rs.total_sales
    FROM RankedSales rs
    WHERE rs.rank <= 5
), Returns AS (
    SELECT 
        wr_returned_date_sk, 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_returns
    FROM web_returns 
    GROUP BY wr_returned_date_sk, wr_item_sk
), EffectiveSales AS (
    SELECT 
        ts.web_site_sk, 
        ts.order_number, 
        COALESCE(ts.total_sales - r.total_returns * i.i_current_price, ts.total_sales) AS net_sales
    FROM TopSales ts
    LEFT JOIN Returns r ON ts.order_number = r.wr_order_number 
    LEFT JOIN item i ON r.wr_item_sk = i.i_item_sk
), CustomerProfile AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        COALESCE(DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(DISTINCT ts.order_number) DESC), 0) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN TopSales ts ON c.c_customer_sk = ts.web_site_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, ca.ca_city, ca.ca_state
)
SELECT 
    cp.c_first_name,
    cp.c_last_name,
    cp.ca_city,
    cp.ca_state,
    es.net_sales,
    CASE 
        WHEN cp.gender_rank = 0 THEN 'Unranked'
        ELSE CAST(cp.gender_rank AS VARCHAR)
    END AS gender_rank_description
FROM EffectiveSales es
JOIN CustomerProfile cp ON es.web_site_sk = cp.c_customer_sk
WHERE es.net_sales > (SELECT AVG(net_sales) FROM EffectiveSales) 
      AND (cp.ca_state IS NOT NULL OR cp.ca_city IS NULL)
ORDER BY cp.ca_state, es.net_sales DESC;
