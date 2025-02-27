WITH RECURSIVE SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, r.r_name,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.total_revenue DESC) AS revenue_rank
    FROM SupplierStats s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.r_name
    FROM RankedSuppliers s
    WHERE s.revenue_rank <= 3
),
CustomerOrders AS (
    SELECT DISTINCT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, 
           CASE 
               WHEN o.o_orderstatus = 'F' THEN 'Completed'
               ELSE 'Pending'
           END AS order_status,
           SUM(l.l_quantity) AS total_quantity,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus
),
FinalOutput AS (
    SELECT co.c_custkey, co.c_name, co.order_status, ts.s_suppkey, ts.s_name, 
           ts.s_acctbal, 
           CASE 
               WHEN ts.s_acctbal IS NULL THEN 'No Supplier'
               WHEN co.total_price > 5000 THEN 'High Value'
               ELSE 'Standard Value'
           END AS customer_value_category
    FROM CustomerOrders co
    LEFT JOIN TopSuppliers ts ON co.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE l.l_quantity > 100
    )
)
SELECT f.*, 
       NTH_VALUE(f.s_name, 2) OVER (PARTITION BY f.c_custkey ORDER BY f.s_acctbal) AS second_supplier_name,
       COALESCE(f.s_acctbal, 0) AS safe_acctbal,
       CASE 
           WHEN f.s_acctbal IS NOT NULL THEN ROUND(f.s_acctbal / NULLIF(f.total_quantity, 0), 2)
           ELSE NULL 
       END AS price_per_unit
FROM FinalOutput f
ORDER BY f.c_custkey, f.s_acctbal DESC;
