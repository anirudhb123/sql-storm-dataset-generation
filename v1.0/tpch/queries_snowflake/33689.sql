WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
AggregatedOrders AS (
    SELECT o.o_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_custkey
),
JoinedData AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, o.order_count, o.total_spent, 
           p.p_partkey, p.p_name, ps.total_availqty,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.total_spent DESC) AS rank
    FROM customer c 
    LEFT JOIN AggregatedOrders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON c.c_custkey = l.l_orderkey
    LEFT JOIN part p ON l.l_partkey = p.p_partkey
    LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
)
SELECT j.c_custkey, j.c_name, j.c_mktsegment, j.order_count, j.total_spent, 
       j.p_partkey, j.p_name, j.total_availqty
FROM JoinedData j
WHERE (j.order_count IS NOT NULL OR j.total_spent IS NULL)
    AND j.rank <= 5
ORDER BY j.c_custkey, j.total_spent DESC;
