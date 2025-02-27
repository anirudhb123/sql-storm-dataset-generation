WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 0 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, oh.depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = (SELECT MIN(l.l_orderkey) FROM lineitem l WHERE l.l_orderkey > oh.o_orderkey)
), SupplierCosts AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
), RegionStats AS (
    SELECT n.n_nationkey, r.r_regionkey, COUNT(DISTINCT c.c_custkey) AS customer_count, AVG(c.c_acctbal) AS avg_acctbal
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_nationkey, r.r_regionkey
), RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank,
           COUNT(*)
           OVER (PARTITION BY p.p_type) AS type_count
    FROM part p
)
SELECT rh.o_orderkey, rh.o_orderdate, rh.o_totalprice, rh.depth,
       rs.customer_count, rs.avg_acctbal,
       rp.p_partkey, rp.p_name, rp.p_retailprice
FROM OrderHierarchy rh
LEFT JOIN RegionStats rs ON rs.customer_count > 10
JOIN RankedParts rp ON rp.price_rank = 1 AND rp.type_count > 5
WHERE rh.o_totalprice > (SELECT AVG(o.o_totalprice) FROM orders o WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year')
ORDER BY rh.o_orderdate DESC, rs.avg_acctbal DESC;
