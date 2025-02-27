WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, c.level + 1
    FROM supplier s
    JOIN SupplierCTE c ON s.s_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name = (SELECT n2.n_name FROM nation n2 WHERE n2.n_nationkey = c.s_suppkey)
    )
    WHERE c.level < 5
),
RegionInfo AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
PartSupplierInfo AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(ls.l_extendedprice * (1 - ls.l_discount)), 0) AS total_revenue,
    COALESCE(rs.nation_count, 0) AS nation_count,
    AVG(ps.total_supply_cost) AS avg_supply_cost,
    MAX(s.s_acctbal) AS max_supplier_acctbal
FROM lineitem ls
JOIN orders o ON ls.l_orderkey = o.o_orderkey
LEFT JOIN RegionInfo rs ON rs.nation_count > 0
JOIN PartSupplierInfo ps ON ps.p_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
)
LEFT JOIN SupplierCTE s ON s.s_suppkey = ls.l_suppkey
WHERE o.o_orderstatus = 'F'
GROUP BY r.r_name, rs.nation_count
HAVING AVG(s.s_acctbal) IS NOT NULL
ORDER BY total_revenue DESC, nation_count DESC
LIMIT 10;
