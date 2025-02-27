WITH RECURSIVE SupplierRank AS (
    SELECT s_suppkey, s_name, s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
    WHERE s_acctbal IS NOT NULL
),
RankSum AS (
    SELECT s_nationkey, SUM(s_acctbal) AS total_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, RANK() OVER (ORDER BY SUM(s.s_acctbal) DESC) AS nation_rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(s.s_suppkey) > 2
)
SELECT 
    r.r_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    ps.ps_availqty,
    (ps.ps_supplycost * ps.ps_availqty) AS total_value,
    CASE 
        WHEN s.s_acctbal IS NULL THEN 'Missing Account Balance'
        ELSE 'Account Balance Available'
    END AS acctbal_status,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY total_value DESC) AS region_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
WHERE r.r_name LIKE '%East%'
  AND (ps.ps_availqty > 0 OR ps.ps_availqty IS NULL)
  AND EXISTS (
      SELECT 1 FROM TopNations tn
      WHERE tn.n_nationkey = n.n_nationkey AND tn.nation_rank <= 3
  )
ORDER BY r.r_regionkey, total_value DESC
FETCH FIRST 10 ROWS ONLY;

-- Additional complexity
WITH valuable_suppliers AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT *
FROM valuable_suppliers
WHERE s_suppkey IN (
    SELECT s_suppkey
    FROM supplier 
    WHERE s_name ILIKE '%premium%'
) 
UNION 
SELECT DISTINCT l.l_shipinstruct, NULL AS s_suppkey
FROM lineitem l
WHERE l_shipmode IN ('AIR', 'SHIP')
  AND l_discount BETWEEN 0.1 AND 0.3
  AND l_returnflag = 'N'
ORDER BY 1;
