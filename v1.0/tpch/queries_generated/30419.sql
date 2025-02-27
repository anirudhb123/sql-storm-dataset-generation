WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_custkey, 1 AS order_level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_orderdate, o.o_custkey, oh.order_level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
),
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, COUNT(ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
TopParts AS (
    SELECT p.*, SUM(l.l_discount * l.l_extendedprice) OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS total_discounted_revenue
    FROM PartSupplier p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT r.r_name,
       n.n_name,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       SUM(o.o_totalprice) AS total_revenue,
       COALESCE(MAX(ps.total_supplycost), 0) AS max_supplier_cost,
       COUNT(tp.p_partkey) AS part_count,
       AVG(tp.total_discounted_revenue) AS avg_discounted_revenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN SupplierStats ps ON ps.s_suppkey IN (SELECT ps2.ps_suppkey
                                                  FROM partsupp ps2 
                                                  WHERE ps2.ps_partkey IN (SELECT p.p_partkey
                                                                            FROM TopParts p))
LEFT JOIN TopParts tp ON tp.p_partkey IN (SELECT p.p_partkey 
                                             FROM part p
                                             WHERE p.p_size > 10)
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_revenue DESC;
