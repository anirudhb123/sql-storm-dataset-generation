
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
HighValueItems AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        CASE 
            WHEN i_current_price > (SELECT AVG(i_current_price) FROM item) THEN 'High' 
            ELSE 'Low' 
        END AS price_category
    FROM item
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_birth_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_birth_year
),
TotalReturns AS (
    SELECT 
        wr_returning_customer_sk AS customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM web_returns
    GROUP BY wr_returning_customer_sk
    HAVING SUM(wr_return_quantity) > 5
)

SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    HVI.i_item_desc,
    HVI.price_category,
    R.total_quantity AS sold_quantity,
    COALESCE(TR.total_return_quantity, 0) AS return_quantity,
    COALESCE(TR.total_return_value, 0) AS return_value
FROM CustomerDetails cd
JOIN RankedSales R ON cd.c_customer_sk = (SELECT ws_bill_customer_sk 
                                            FROM web_sales 
                                            WHERE ws_item_sk = R.ws_item_sk 
                                            ORDER BY ws_net_profit DESC 
                                            LIMIT 1)
JOIN HighValueItems HVI ON R.ws_item_sk = HVI.i_item_sk
LEFT JOIN TotalReturns TR ON cd.c_customer_sk = TR.customer_sk
WHERE 
    (cd.total_orders > 3 AND cd.cd_marital_status = 'M') 
    OR (cd.cd_gender = 'F' AND cd.total_orders > 1)
ORDER BY 
    HVI.price_category DESC, 
    R.total_quantity DESC, 
    cd.c_last_name ASC
LIMIT 100 OFFSET 10;
