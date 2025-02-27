WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, co.level + 1
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON co.o_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O' AND co.level < 5
),
LineitemStats AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_partkey
),
SupplierRevenue AS (
    SELECT s.s_suppkey, SUM(ls.revenue) AS total_revenue
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN LineitemStats ls ON ps.ps_partkey = ls.l_partkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sr.total_revenue,
           RANK() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM supplier s
    JOIN SupplierRevenue sr ON s.s_suppkey = sr.s_suppkey
)
SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, 
       COALESCE(ts.s_name, 'Unknown Supplier') AS supplier_name,
       ts.total_revenue
FROM CustomerOrders co
LEFT JOIN TopSuppliers ts ON co.o_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_returnflag = 'N')
WHERE ts.revenue_rank <= 5
ORDER BY co.o_orderdate DESC, co.o_orderkey
LIMIT 100;
