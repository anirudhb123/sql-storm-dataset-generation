
WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, 
           DENSE_RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), QualifiedRegions AS (
    SELECT r.r_regionkey,
           r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(DISTINCT n.n_nationkey) > 1
), TopSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 5
)
SELECT c.c_custkey, 
       c.c_name, 
       o.o_orderkey, 
       o.o_orderdate, 
       lp.l_partkey, 
       rp.total_cost, 
       qr.nation_count
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem lp ON o.o_orderkey = lp.l_orderkey
JOIN RankedParts rp ON lp.l_partkey = rp.p_partkey AND rp.rank = 1
JOIN QualifiedRegions qr ON qr.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = c.c_nationkey)
JOIN TopSuppliers ts ON ts.s_suppkey = lp.l_suppkey
WHERE o.o_orderdate >= DATE '1996-01-01' 
AND o.o_orderstatus = 'O'
ORDER BY o.o_orderdate DESC, rp.total_cost DESC;
