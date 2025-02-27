WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, ts.total_cost + SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN TopSuppliers ts ON ts.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, ts.total_cost
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, co.order_count, co.total_spent
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    WHERE total_spent > 10000
),
RegionNations AS (
    SELECT r.r_name, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name, n.n_name
)
SELECT 
    rnr.r_name,
    rnr.n_name,
    ts.s_name,
    hvc.c_name,
    hvc.order_count,
    hvc.total_spent,
    ROW_NUMBER() OVER (PARTITION BY rnr.r_name ORDER BY hvc.total_spent DESC) AS rank
FROM RegionNations rnr
JOIN TopSuppliers ts ON rnr.supplier_count > 0
JOIN HighValueCustomers hvc ON hvc.total_spent > 0
WHERE ts.total_cost IS NOT NULL
ORDER BY rnr.r_name, rank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
