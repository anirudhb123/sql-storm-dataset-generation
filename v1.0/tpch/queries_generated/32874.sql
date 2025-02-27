WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS hierarchy_level
    FROM customer c
    WHERE c.c_acctbal > 10000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany')
    WHERE c.c_acctbal > ch.c_acctbal
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           AVG(ps.ps_supplycost) AS avg_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT o.o_orderkey, o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           c.c_mktsegment,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus, c.c_mktsegment
)
SELECT r.r_name, 
       SUM(COALESCE(cs.total_revenue, 0)) AS total_revenue,
       SUM(COALESCE(ss.total_cost, 0)) AS total_supplier_cost,
       COUNT(DISTINCT ch.c_custkey) AS active_customers,
       COUNT(DISTINCT s.s_suppkey) FILTER (WHERE ss.supplier_rank <= 3) AS top_suppliers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN CustomerOrderStats cs ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = 'Germany') 
LEFT JOIN CustomerHierarchy ch ON ch.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
GROUP BY r.r_name
ORDER BY total_revenue DESC;
