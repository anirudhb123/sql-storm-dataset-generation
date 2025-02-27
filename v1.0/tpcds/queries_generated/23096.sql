
WITH SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY
        ws_item_sk
),
TopSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_sales,
        sd.order_count,
        CASE 
            WHEN cd.gender = 'M' THEN 'Male'
            WHEN cd.gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS customer_gender,
        cd.cd_demo_sk
    FROM
        SalesData sd
    JOIN
        customer c ON c.c_customer_sk IN (SELECT sr_customer_sk FROM store_returns WHERE sr_return_quantity > 0)
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        sd.sales_rank = 1
),
ExtremePromo AS (
    SELECT
        p.p_promo_name,
        p.p_discount_active,
        SUM(CASE WHEN cs_ext_sales_price IS NOT NULL THEN cs_ext_sales_price ELSE 0 END) AS promo_total_sales,
        COUNT(DISTINCT cs_order_number) AS promo_order_count
    FROM
        catalog_sales cs
    JOIN
        promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        p.p_discount_active = 'Y'
    GROUP BY
        p.p_promo_name, p.p_discount_active
),
FinalResults AS (
    SELECT
        ts.ws_item_sk,
        ts.total_sales,
        ts.order_count,
        ep.promo_total_sales,
        ep.promo_order_count,
        (ts.total_sales - COALESCE(ep.promo_total_sales, 0)) AS net_sales_after_promo,
        CASE 
            WHEN ep.promo_order_count IS NULL THEN 'No Promotion'
            ELSE 'With Promotion'
        END AS promo_status
    FROM
        TopSales ts
    LEFT JOIN
        ExtremePromo ep ON ts.sales_rank = 1
)
SELECT
    f.ws_item_sk,
    f.total_sales,
    f.order_count,
    f.net_sales_after_promo,
    f.promo_status,
    CASE 
        WHEN f.net_sales_after_promo < 0 THEN 'Loss'
        WHEN f.net_sales_after_promo = 0 THEN 'Break Even'
        ELSE 'Profit'
    END AS profitability
FROM
    FinalResults f
WHERE
    f.total_sales IS NOT NULL
ORDER BY
    f.total_sales DESC, f.net_sales_after_promo ASC
LIMIT 50;
