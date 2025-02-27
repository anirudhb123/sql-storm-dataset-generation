WITH RECURSIVE PriceHierarchy AS (
    SELECT ps_partkey, SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM partsupp
    GROUP BY ps_partkey
    UNION ALL
    SELECT p.p_partkey, ph.total_cost + p.p_retailprice
    FROM part p
    JOIN PriceHierarchy ph ON ph.ps_partkey = p.p_partkey
), RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost) AS total_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), HighestPricedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
), NationWithSuppliers AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name, n.supplier_count, hp.p_name, hp.p_retailprice, 
       ph.total_cost, rs.total_supplycost, 
       CASE WHEN rs.rank IS NULL THEN 'No Supplier' ELSE 'Has Supplier' END AS supplier_status
FROM NationWithSuppliers n
LEFT JOIN HighestPricedParts hp ON n.n_nationkey = hp.rank
LEFT JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
LEFT JOIN PriceHierarchy ph ON hp.p_partkey = ph.ps_partkey
WHERE (hp.rank IS NOT NULL OR rs.total_supplycost > 10000) 
AND ph.total_cost IS NOT NULL
ORDER BY n.n_name, hp.p_retailprice DESC;
