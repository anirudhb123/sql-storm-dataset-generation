
WITH RecursivePart AS (
    SELECT p_partkey, p_name, p_brand, p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p_mfgr ORDER BY p_retailprice DESC) AS price_rank
    FROM part
    WHERE p_size IN (SELECT DISTINCT p_size FROM part WHERE p_type LIKE '%screw%')
),
FilteredNations AS (
    SELECT n_nationkey, n_name, r_name AS region_name
    FROM nation
    JOIN region ON n_regionkey = r_regionkey
    WHERE n_name NOT IN (SELECT DISTINCT SUBSTRING(c_name, 1, 5) FROM customer WHERE c_acctbal > 1000)
),
OrderStats AS (
    SELECT o_orderkey, o_custkey, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM orders
    JOIN lineitem ON o_orderkey = l_orderkey
    WHERE o_orderdate >= '1996-01-01'
    GROUP BY o_orderkey, o_custkey
),
SupplierDetails AS (
    SELECT s_suppkey, s_name, MAX(ps_supplycost) AS max_supply_cost
    FROM supplier
    JOIN partsupp ON s_suppkey = ps_suppkey
    GROUP BY s_suppkey, s_name
    HAVING COUNT(ps_partkey) > 5
)
SELECT P.p_partkey, P.p_name, R.region_name, O.total_revenue,
       S.max_supply_cost,
       CASE 
           WHEN O.total_revenue IS NULL THEN 'No Revenue'
           ELSE 'Revenue Exists'
       END AS revenue_status,
       CONCAT('Part: ', P.p_name, ' | Max Cost: ', COALESCE(S.max_supply_cost::STRING, 'N/A')) AS details
FROM RecursivePart P
LEFT JOIN FilteredNations R ON R.n_nationkey = 
    (SELECT n.n_nationkey FROM nation n ORDER BY RANDOM() LIMIT 1)
LEFT JOIN OrderStats O ON O.o_custkey = 
    (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = R.n_nationkey LIMIT 1)
FULL OUTER JOIN SupplierDetails S ON S.s_suppkey = 
    (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = P.p_partkey ORDER BY ps.ps_supplycost DESC LIMIT 1)
WHERE P.price_rank = 1 AND (S.max_supply_cost IS NULL OR S.max_supply_cost > 100)
ORDER BY R.region_name, P.p_retailprice DESC;
