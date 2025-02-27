WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
),
RegionSuppliers AS (
    SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT rd.r_name, rd.supplier_count, sd.s_name, sd.total_cost, co.order_count
FROM RegionSuppliers rd
LEFT JOIN SupplierDetails sd ON rd.supplier_count > 0
LEFT JOIN CustomerOrders co ON co.order_count > 0
WHERE sd.total_cost > 50000
ORDER BY rd.r_name, sd.total_cost DESC, co.order_count DESC;
