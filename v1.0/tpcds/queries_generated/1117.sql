
WITH SalesData AS (
    SELECT
        c.c_customer_id,
        s.s_store_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS transaction_count,
        AVG(ss.ss_sales_price) AS avg_sale_price
    FROM
        customer AS c
    JOIN
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN
        store AS s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY
        c.c_customer_id, s.s_store_id
),
CustomerDemo AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        customer_demographics AS cd
    LEFT JOIN
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
RankedSales AS (
    SELECT
        sd.c_customer_id,
        sd.s_store_id,
        sd.total_sales,
        sd.transaction_count,
        sd.avg_sale_price,
        DENSE_RANK() OVER (PARTITION BY sd.s_store_id ORDER BY sd.total_sales DESC) AS store_sales_rank
    FROM
        SalesData AS sd
)
SELECT
    r.c_customer_id,
    r.s_store_id,
    COALESCE(cd.cd_gender, 'U') AS gender,
    COALESCE(cd.cd_marital_status, 'U') AS marital_status,
    CASE
        WHEN cd.ib_lower_bound IS NOT NULL AND cd.ib_upper_bound IS NOT NULL THEN
            CONCAT('Income Band: $', cd.ib_lower_bound, ' to $', cd.ib_upper_bound)
        ELSE
            'Income Band Not Available'
    END AS income_band,
    r.total_sales,
    r.transaction_count,
    r.avg_sale_price,
    r.store_sales_rank
FROM
    RankedSales AS r
LEFT JOIN
    CustomerDemo AS cd ON r.c_customer_id = cd.cd_demo_sk
WHERE
    r.store_sales_rank <= 10
ORDER BY
    r.s_store_id, r.total_sales DESC;
