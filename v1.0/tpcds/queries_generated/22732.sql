
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.wr_returning_customer_sk,
        cr.total_returned_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cr.total_returned_quantity DESC) AS customer_rank
    FROM CustomerReturns cr
    JOIN customer_demographics cd ON cr.wr_returning_customer_sk = cd.cd_demo_sk
    WHERE cr.total_returned_quantity > 5 
),
AggregatedReturns AS (
    SELECT 
        hrc.wr_returning_customer_sk,
        SUM(hrc.total_returned_quantity) AS overall_returned_quantity,
        AVG(hrc.return_count) AS average_return_count,
        COUNT(DISTINCT cd.cd_demo_sk) AS unique_demographics
    FROM HighReturnCustomers hrc
    JOIN customer_demographics cd ON hrc.wr_returning_customer_sk = cd.cd_demo_sk
    GROUP BY hrc.wr_returning_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ar.overall_returned_quantity,
    ar.average_return_count,
    COALESCE(cd.cd_gender, 'Unknown') AS customer_gender,
    COALESCE(cd.cd_marital_status, 'Unknown') AS customer_marital_status
FROM AggregatedReturns ar
JOIN customer c ON ar.wr_returning_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
WHERE ar.overall_returned_quantity > (
      SELECT AVG(overall_returned_quantity) 
      FROM AggregatedReturns
  ) 
  AND (ca.ca_state IS NOT NULL OR ca.ca_city IS NOT NULL)
ORDER BY ar.overall_returned_quantity DESC, ca.ca_city;
