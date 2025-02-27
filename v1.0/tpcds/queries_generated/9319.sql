
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_ship_date_sk,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.sales_price) DESC) AS rank_sales
    FROM web_sales ws
    JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 2023 AND cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY ws.web_site_sk, ws_item_sk, ws_order_number, ws_sales_price, ws_ship_date_sk
),
TopSales AS (
    SELECT
        rs.web_site_sk,
        rs.ws_item_sk,
        SUM(rs.ws_sales_price) AS total_sales
    FROM RankedSales rs
    WHERE rs.rank_sales <= 10
    GROUP BY rs.web_site_sk, rs.ws_item_sk
)
SELECT
    wa.w_warehouse_id,
    tsa.web_site_sk,
    tsa.ws_item_sk,
    tsa.total_sales,
    wa.w_city,
    wa.w_state
FROM TopSales tsa
JOIN warehouse wa ON wa.w_warehouse_sk = (SELECT inv.inv_warehouse_sk 
                                            FROM inventory inv 
                                            WHERE inv.inv_item_sk = tsa.ws_item_sk 
                                            ORDER BY inv.inv_quantity_on_hand DESC 
                                            LIMIT 1)
ORDER BY total_sales DESC
LIMIT 100;
