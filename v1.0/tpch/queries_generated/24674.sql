WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal,
           CASE WHEN p.p_type LIKE '%WOOD%' THEN 'Wooden Supplier' ELSE 'Other Supplier' END AS supplier_type
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size BETWEEN 1 AND 10
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal,
           'Nested Supplier' AS supplier_type
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.s_acctbal IS NOT NULL
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate > (CURRENT_DATE - INTERVAL '1 YEAR')
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_addr, 
           COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 500
    GROUP BY c.c_custkey
)

SELECT DISTINCT r.r_name, COALESCE(o.order_rank, 0) AS order_rank, 
                SUM(sp.s_acctbal) OVER (PARTITION BY r.r_name) AS regional_total,
                CASE WHEN co.total_orders IS NULL THEN 'No Orders' ELSE 'Has Orders' END AS order_status,
                STRING_AGG(DISTINCT sh.s_name, ', ') FILTER (WHERE sh.s_acctbal > 1000) AS high_value_suppliers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN RankedOrders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN CustomerOrders co ON co.c_custkey = o.o_custkey
WHERE (s.s_acctbal IS NOT NULL OR sh.s_acctbal IS NULL) 
  AND (sh.supplier_type = 'Wooden Supplier' OR n.n_name IS NULL)
GROUP BY r.r_name, o.order_rank, co.total_orders;
