WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal <= sh.s_acctbal AND sh.level < 5
), 

PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),

TopRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey
    HAVING COUNT(n.n_nationkey) > 1
),

OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate < CURRENT_DATE AND l.l_shipstatus IS NOT NULL
    GROUP BY o.o_orderkey, o.o_custkey
),

CustomerRank AS (
    SELECT c.c_custkey, RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(od.total_order_value) DESC) AS cust_rank
    FROM customer c
    JOIN OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY c.c_custkey, c.c_mktsegment
)

SELECT 
    ph.p_name,
    ph.p_brand,
    SUM(ps.total_availqty) AS total_avail_quantity,
    COALESCE(cr.cust_rank, 0) AS customer_rank,
    COUNT(DISTINCT sh.s_suppkey) AS total_suppliers
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN CustomerRank cr ON cr.c_custkey = (SELECT MIN(c.c_custkey) 
                                             FROM customer c 
                                             WHERE c.c_nationkey IN (SELECT n.n_nationkey 
                                                                     FROM nation n 
                                                                     WHERE n.n_regionkey IN (SELECT r.r_regionkey 
                                                                                             FROM TopRegions r)))
LEFT JOIN SupplierHierarchy sh ON p.p_partkey = (SELECT ps.ps_partkey 
                                                  FROM partsupp ps 
                                                  WHERE ps.ps_suppkey = sh.s_suppkey)
GROUP BY p.p_partkey, p.p_name, p.p_brand
HAVING SUM(ps.total_availqty) > (SELECT AVG(total_availqty) FROM PartSupplier)
   OR COALESCE(cr.cust_rank, 0) = 1
ORDER BY total_avail_quantity DESC, p_name;
