WITH RECURSIVE TopSuppliers AS (
    SELECT s_suppkey, 
           s_name, 
           s_acctbal, 
           1 AS level
    FROM supplier
    WHERE s_acctbal = (SELECT MAX(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           ts.level + 1
    FROM supplier s
    JOIN TopSuppliers ts ON s.s_acctbal < ts.s_acctbal
    WHERE ts.level < 5
), FilteredCustomer AS (
    SELECT c_custkey, 
           c_name, 
           c_acctbal,
           (CASE 
                WHEN c_acctbal IS NULL THEN 'No Balance'
                WHEN c_acctbal >= (SELECT AVG(c_acctbal) FROM customer) THEN 'Above Average'
                ELSE 'Below Average'
           END) AS balance_category
    FROM customer
    WHERE c_nationkey IN (SELECT DISTINCT n_nationkey FROM nation WHERE n_name LIKE 'A%')
), OrderDetails AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate < CURRENT_DATE
    GROUP BY o.o_orderkey, o.o_custkey
), SupplierRevenue AS (
    SELECT p.p_partkey, 
           p.p_name,
           SUM(ps.ps_supplycost * l.l_quantity) AS supplier_total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY p.p_partkey, p.p_name
), CombinedResults AS (
    SELECT c.c_custkey, 
           c.c_name, 
           od.total_revenue,
           sr.supplier_total_cost,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY od.total_revenue DESC) AS rn
    FROM FilteredCustomer c
    LEFT JOIN OrderDetails od ON c.c_custkey = od.o_custkey
    FULL OUTER JOIN SupplierRevenue sr ON od.o_custkey IS NULL OR sr.p_partkey IS NULL
    WHERE c.balance_category = 'Above Average'
      OR sr.supplier_total_cost IS NOT NULL
)
SELECT 
    cr.c_custkey, 
    cr.c_name,
    COALESCE(cr.total_revenue, 0) AS total_revenue,
    COALESCE(cr.supplier_total_cost, 0) AS supplier_total_cost,
    (CASE 
        WHEN cr.total_revenue IS NOT NULL THEN cr.total_revenue / NULLIF(cr.supplier_total_cost, 0)
        ELSE 0
    END) AS revenue_to_cost_ratio
FROM CombinedResults cr
WHERE cr.rn = 1
ORDER BY cr.total_revenue DESC, cr.supplier_total_cost ASC
LIMIT 100;
