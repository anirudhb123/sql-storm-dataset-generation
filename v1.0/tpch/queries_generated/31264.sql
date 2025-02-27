WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, 1 AS level
    FROM part
    WHERE p_size < 30
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_partkey = ph.p_partkey
    WHERE ph.level < 5
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
)
SELECT DISTINCT
    c.c_name,
    COALESCE(SUM(l.l_extendedprice), 0) AS total_revenue,
    r.region,
    (SELECT COUNT(DISTINCT o.o_orderkey)
     FROM orders o
     WHERE o.o_custkey = c.c_custkey) AS order_count,
    ph.level AS part_hierarchy_level,
    ts.total_cost AS supplier_total_cost
FROM customer c
LEFT JOIN lineitem l ON c.c_custkey = l.l_orderkey
LEFT JOIN (SELECT n.n_regionkey, r.r_name AS region
            FROM nation n 
            JOIN region r ON n.n_regionkey = r.r_regionkey) r ON c.c_nationkey = r.n_regionkey
LEFT JOIN PartHierarchy ph ON ph.p_partkey = l.l_partkey
LEFT JOIN TopSuppliers ts ON ts.s_suppkey = l.l_suppkey
WHERE l.l_discount > 0.1 AND l.l_returnflag = 'N'
GROUP BY c.c_name, r.region, ph.level, ts.total_cost
HAVING total_revenue > 50000
ORDER BY total_revenue DESC, c.c_name;
