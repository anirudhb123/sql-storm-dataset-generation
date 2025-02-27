
WITH DateRange AS (
    SELECT d_year, d_month_seq
    FROM date_dim
    WHERE d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(ws_item_sk) AS total_items
    FROM web_sales 
    JOIN DateRange ON ws_sold_date_sk = d_date_sk
    GROUP BY ws_bill_customer_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.total_items, 0) AS total_items
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
),
IncomeBandData AS (
    SELECT ib.ib_income_band_sk, COUNT(cd.c_customer_sk) AS num_customers
    FROM customer_data cd
    JOIN household_demographics hd ON cd.cd_income_band_sk = hd.hd_income_band_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
),
RankedIncomeBands AS (
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, num_customers,
           RANK() OVER (ORDER BY num_customers DESC) AS income_rank
    FROM IncomeBandData ib
)
SELECT
    rib.income_band_sk,
    rib.ib_lower_bound,
    rib.ib_upper_bound,
    rib.num_customers,
    rib.income_rank
FROM RankedIncomeBands rib
WHERE rib.income_rank <= 10
ORDER BY rib.income_rank;
