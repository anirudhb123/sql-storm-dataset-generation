
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000
    UNION ALL
    SELECT sh.s_suppkey, sh.s_name, sh.s_acctbal, sh.hierarchy_level + 1
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 50
), 
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS item_count,
           RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), 
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 50000
)
SELECT p.p_partkey, p.p_name, 
       COALESCE(SUM(ps.ps_availqty), 0) AS total_available_qty, 
       MAX(ss.total_revenue) AS max_order_revenue,
       LISTAGG(DISTINCT c.c_name, ', ') WITHIN GROUP (ORDER BY c.c_name) AS top_customers_names
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN OrderStats ss ON ss.o_orderkey = (SELECT o.o_orderkey 
                                             FROM orders o 
                                             WHERE o.o_custkey IN (SELECT c.custkey FROM TopCustomers) 
                                             ORDER BY o.o_orderkey DESC 
                                             LIMIT 1)
LEFT JOIN TopCustomers c ON c.c_custkey = (SELECT o.o_custkey 
                                             FROM orders o 
                                             WHERE o.o_orderkey = ss.o_orderkey)
GROUP BY p.p_partkey, p.p_name
HAVING MAX(ss.total_revenue) > 1000 OR COALESCE(SUM(ps.ps_availqty), 0) < 10
ORDER BY p.p_partkey;
