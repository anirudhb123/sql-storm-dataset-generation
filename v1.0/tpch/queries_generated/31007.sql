WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_brand, p_container, p_retailprice
    FROM part
    WHERE p_size > 10
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_container, p.p_retailprice
    FROM part p
    INNER JOIN PartHierarchy ph ON p.p_partkey > ph.p_partkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_acctbal, 
           SUM(ps.ps_availqty) AS total_available, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_acctbal
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_sequence
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT r.r_name, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(ss.total_available) AS total_available_quantity,
       COALESCE(SUM(od.total_revenue), 0) AS total_revenue,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ss.avg_supply_cost) AS median_supply_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierStats ss ON ss.s_acctbal > 1000
LEFT JOIN OrderDetails od ON od.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'F')
JOIN PartHierarchy ph ON ph.p_brand = 'Brand#14'
WHERE ph.p_retailprice > 100
GROUP BY r.r_name
HAVING AVG(ph.p_retailprice) > 200
ORDER BY nation_count DESC, total_revenue DESC;
