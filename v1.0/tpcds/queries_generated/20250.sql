
WITH RECURSIVE OrderReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_item_sk,
        wr_order_number,
        wr_return_quantity,
        wr_return_amt,
        wr_return_tax,
        1 AS recursive_depth
    FROM web_returns
    WHERE wr_returned_date_sk = (
        SELECT MAX(wr_returned_date_sk)
        FROM web_returns
    )
    
    UNION ALL
    
    SELECT 
        wr.returning_customer_sk,
        wr.item_sk,
        wr.order_number,
        wr.return_quantity,
        wr.return_amt,
        wr.return_tax,
        recursive_depth + 1
    FROM web_returns wr
    JOIN OrderReturns orr ON wr.returning_customer_sk = orr.wr_returning_customer_sk
    WHERE orr.recursive_depth < 3 
      AND wr.returned_date_sk = (
        SELECT MAX(returned_date_sk) 
        FROM web_returns 
        WHERE returning_customer_sk = orr.wr_returning_customer_sk
      )
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT o.item_sk) AS return_count,
        SUM(o.return_quantity) AS total_return_quantity,
        SUM(o.return_amt) AS total_return_amt,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(o.return_amt) DESC) AS return_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN OrderReturns orr ON c.c_customer_sk = orr.w_returning_customer_sk
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        hd.hd_income_band_sk
)
SELECT 
    DISTINCT cd.c_customer_id AS Customer_ID,
    cd.c_first_name AS First_Name,
    cd.c_last_name AS Last_Name,
    cd.cd_gender AS Gender,
    cd.cd_marital_status AS Marital_Status,
    CASE 
        WHEN cd.income_band BETWEEN 1 AND 4 THEN 'Low Income'
        WHEN cd.income_band BETWEEN 5 AND 8 THEN 'Middle Income'
        WHEN cd.income_band >= 9 THEN 'High Income'
        ELSE 'No Income Data'
    END AS Income_Classification,
    SUM(COALESCE(cd.total_return_quantity, 0)) AS Total_Return_Quantity,
    SUM(COALESCE(cd.total_return_amt, 0)) AS Total_Return_Amount,
    AVG(cd.return_rank) AS Average_Return_Rank
FROM CustomerDetails cd
LEFT JOIN store_sales ss ON cd.c_customer_id = ss.ss_customer_sk
WHERE cd.return_count > 0 
  AND EXISTS (SELECT 1 FROM date_dim dd WHERE dd.d_date_sk = ss.ss_sold_date_sk AND dd.d_year = 2023)
GROUP BY 
    cd.c_customer_id, 
    cd.c_first_name, 
    cd.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status
HAVING 
    SUM(COALESCE(cd.total_return_quantity, 0)) > 5 
ORDER BY cd.c_last_name, cd.c_first_name;
