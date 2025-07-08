
WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, 1 AS level
    FROM part
    WHERE p_size BETWEEN 10 AND 20

    UNION ALL

    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice, ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON ph.p_partkey = p.p_partkey
    WHERE p.p_size < 10
),
SupplierStats AS (
    SELECT s.s_nationkey, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
CustomerOrderStats AS (
    SELECT c.c_nationkey,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1995-01-01'
    GROUP BY c.c_nationkey
)
SELECT r.r_name AS region,
       n.n_name AS nation,
       COALESCE(ss.supplier_count, 0) AS supplier_count,
       COALESCE(ss.total_cost, 0) AS total_cost,
       COALESCE(os.order_count, 0) AS order_count,
       COALESCE(os.avg_order_value, 0) AS avg_order_value
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN CustomerOrderStats os ON n.n_nationkey = os.c_nationkey
WHERE EXISTS (SELECT 1 FROM PartHierarchy ph WHERE ph.p_size > 5)
ORDER BY r.r_name, n.n_name;
