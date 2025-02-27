WITH RecursiveNations AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE 'Eu%')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, rn.level + 1
    FROM nation n
    JOIN RecursiveNations rn ON n.n_regionkey = rn.n_nationkey
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_comment IS NOT NULL)
      AND s.s_name LIKE '%Corp%'
      AND COALESCE(s.s_comment, 'No Comment') NOT LIKE '%obsolete%'
),
AggregateParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS TotalAvailable
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 100
),
TopOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as OrderRank
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(sum(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    rn.n_name AS nation_name,
    ss.s_name AS supplier_name
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN FilteredSuppliers ss ON l.l_suppkey = ss.s_suppkey
JOIN TopOrders oo ON l.l_orderkey = oo.o_orderkey
JOIN RecursiveNations rn ON ss.s_nationkey = rn.n_nationkey
JOIN AggregateParts ap ON ap.ps_partkey = p.p_partkey
WHERE p.p_retailprice BETWEEN 10 AND 500
  AND (l.l_returnflag = 'N' OR (l.l_returnflag IS NULL AND l.l_linenumber = 1))
GROUP BY p.p_name, p.p_brand, rn.n_name, ss.s_name
HAVING total_revenue > 10000
   AND COUNT(DISTINCT oo.o_orderkey) > 5
ORDER BY total_revenue DESC, p.p_name
LIMIT 10;
