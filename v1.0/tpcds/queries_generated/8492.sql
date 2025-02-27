
WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk AS customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_returned_amount,
        COUNT(DISTINCT cr_order_number) AS total_returned_orders
    FROM
        catalog_returns
    GROUP BY
        cr_returning_customer_sk
),
FilteredCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        chd.hd_income_band_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COALESCE(cr.total_returned_quantity, 0) AS total_returns,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        CASE
            WHEN SUM(ws.ws_sales_price) > 0 THEN 
                (COALESCE(cr.total_returned_amount, 0) / SUM(ws.ws_sales_price)) * 100
            ELSE 0
        END AS return_rate
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics chd ON c.c_current_hdemo_sk = chd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.customer_sk
    WHERE
        cd.cd_marital_status = 'M' AND
        cd.cd_gender = 'F'
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_education_status, chd.hd_income_band_sk
),
RankedCustomers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY return_rate DESC) AS customer_rank
    FROM
        FilteredCustomers
)
SELECT
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.total_sales,
    c.total_returns,
    c.total_returned_amount,
    c.return_rate
FROM
    RankedCustomers c
WHERE
    c.customer_rank <= 10
ORDER BY
    c.return_rate DESC;
