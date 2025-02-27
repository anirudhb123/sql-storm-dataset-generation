
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 0 AS level
    FROM customer c
    WHERE c.c_customer_sk = (SELECT MIN(c2.c_customer_sk) FROM customer c2)

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 5
),
IncomeBands AS (
    SELECT ib.ib_income_band_sk, COUNT(cd.cd_demo_sk) AS count
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY ib.ib_income_band_sk
    HAVING COUNT(cd.cd_demo_sk) IS NOT NULL AND COUNT(cd.cd_demo_sk) > 5
),
CustomerReturnData AS (
    SELECT sr_customer_sk, SUM(sr_return_amt) AS total_return_amt, COUNT(*) AS return_count
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_customer_sk
),
WebReturnStats AS (
    SELECT wr_returning_customer_sk, SUM(wr_return_amt) AS total_web_return_amt
    FROM web_returns
    GROUP BY wr_returning_customer_sk
)
SELECT ch.c_first_name, ch.c_last_name, 
       COALESCE(cr.total_return_amt, 0) AS total_store_return,
       COALESCE(wr.total_web_return_amt, 0) AS total_web_return,
       (COALESCE(cr.total_return_amt, 0) + COALESCE(wr.total_web_return_amt, 0)) AS total_combined_return,
       ib.ib_income_band_sk,
       (ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY COALESCE(cr.total_return_amt, 0) + COALESCE(wr.total_web_return_amt, 0) DESC)) AS rank_within_income_band
FROM CustomerHierarchy ch
LEFT JOIN CustomerReturnData cr ON ch.c_customer_sk = cr.sr_customer_sk
LEFT JOIN WebReturnStats wr ON ch.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN IncomeBands ib ON ch.c_current_cdemo_sk = ib.ib_income_band_sk
WHERE (ch.c_current_cdemo_sk IS NOT NULL OR ch.c_current_cdemo_sk IS NULL)
  AND (COALESCE(cr.total_return_amt, 0) + COALESCE(wr.total_web_return_amt, 0) > 0 OR (COALESCE(cr.total_return_amt, 0) + COALESCE(wr.total_web_return_amt, 0) IS NULL))
  AND ch.c_first_name NOT LIKE '%Test%'
ORDER BY ib.ib_income_band_sk, total_combined_return DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
