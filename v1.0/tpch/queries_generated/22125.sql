WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CAST(s.s_name AS VARCHAR(55)) AS hierarchy_path
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CAST(CONCAT(sh.hierarchy_path, ' -> ', s.s_name) AS VARCHAR(55))
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.s_suppkey <> s.s_suppkey AND LENGTH(sh.hierarchy_path) < 55
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2021-01-01'
      AND o.o_orderstatus IN ('F', 'O')
    GROUP BY c.c_custkey, c.c_name
),
PartSales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY p.p_partkey, p.p_name
),
NationAggregates AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           COALESCE(SUM(s.s_acctbal), 0) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)

SELECT 
    ph.hierarchy_path AS supplier_hierarchy, 
    pa.total_revenue AS part_revenue, 
    ca.c_name AS customer_name, 
    ca.total_spent AS customer_spending,
    na.n_name AS nation_name,
    na.supplier_count AS nation_supplier_count,
    na.total_acctbal AS nation_total_acctbal,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY total_revenue DESC) AS revenue_rank
FROM PartSales pa
JOIN CustomerOrders ca ON pa.order_count > ca.order_count
FULL OUTER JOIN NationAggregates na ON ca.c_custkey = na.n_nationkey
CROSS JOIN SupplierHierarchy ph 
WHERE pa.total_revenue > (SELECT AVG(total_revenue) FROM PartSales)
  AND (na.nation_supplier_count IS NOT NULL OR na.total_acctbal IS NULL)
ORDER BY part_revenue DESC, customer_spending ASC;
