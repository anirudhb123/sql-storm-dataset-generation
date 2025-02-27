WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, CAST(s.s_name AS varchar(255)) AS full_name
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, CAST(CONCAT(sh.full_name, ' > ', s.s_name) AS varchar(255))
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_nationkey
),  
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)
SELECT n.n_name, 
       SUM(COALESCE(ps.ps_availqty, 0)) AS total_available,
       AVG(COALESCE(ps.ps_supplycost, 0)) AS average_supplycost,
       COUNT(DISTINCT ci.c_custkey) AS unique_customers,
       COUNT(DISTINCT l.l_orderkey) AS total_orders,
       ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN PartSupplier ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN CustomerOrders ci ON ci.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE (o.o_orderstatus = 'F' OR o.o_orderdate >= DATE '2022-01-01')
GROUP BY n.n_name
HAVING SUM(ps.ps_availqty) > 100
ORDER BY total_available DESC, average_supplycost ASC;
