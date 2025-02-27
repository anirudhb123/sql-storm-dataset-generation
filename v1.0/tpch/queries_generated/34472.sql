WITH RECURSIVE SupplierRanking AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank,
           n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT * FROM SupplierRanking
    WHERE rank <= 5
),
ProductStats AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, 
       ps.p_name, 
       ps.supplier_count, 
       ps.total_revenue, 
       co.order_count, 
       co.total_spent
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN TopSuppliers ts ON n.n_nationkey = ts.s_suppkey
JOIN ProductStats ps ON ps.supplier_count > 10
FULL OUTER JOIN CustomerOrders co ON co.order_count > 0
WHERE co.total_spent IS NOT NULL OR ts.s_acctbal IS NOT NULL
ORDER BY r.r_name, ps.total_revenue DESC
LIMIT 100;
