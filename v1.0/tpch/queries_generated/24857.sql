WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 2 AND s.s_suppkey <> sh.s_suppkey
),
PriceAnalysis AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * l.l_quantity) AS TotalCost, 
           AVG(l.l_extendedprice - l.l_discount) AS AvgNetPrice
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY p.p_partkey
),
NationsWithComments AS (
    SELECT n.n_nationkey, n.n_name, 
           CASE WHEN n.n_comment IS NULL THEN 'No Comment' ELSE n.n_comment END AS Comment
    FROM nation n
    WHERE n.n_name IS NOT NULL
),
FinalResults AS (
    SELECT sh.s_name AS SupplierName, n.n_name AS NationName, 
           pa.TotalCost, pa.AvgNetPrice, 
           CASE WHEN pa.AvgNetPrice > 100 THEN 'High Value'
                WHEN pa.AvgNetPrice IS NULL THEN 'Missing Price Data'
                ELSE 'Standard Value'
           END AS ValueCategory,
           CONCAT(sh.s_name, ' from ', n.n_name) AS SupplierInfo
    FROM SupplierHierarchy sh
    JOIN NationsWithComments n ON sh.s_nationkey = n.n_nationkey
    LEFT JOIN PriceAnalysis pa ON sh.s_suppkey = pa.p_partkey
)
SELECT *
FROM FinalResults
WHERE TotalCost IS NOT NULL 
AND (ValueCategory = 'High Value' OR ValueCategory = 'Missing Price Data')
ORDER BY TotalCost DESC NULLS FIRST
LIMIT 10;
