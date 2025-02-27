WITH RECURSIVE RegionHierarchy AS (
    SELECT r.r_regionkey, r.r_name, 1 AS level
    FROM region r
    WHERE r.r_name LIKE 'A%'
    
    UNION ALL
    
    SELECT r.r_regionkey, CONCAT(rh.r_name, ' > ', r.r_name), rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey = rh.r_regionkey + 1
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT sp.s_suppkey, sp.s_name
    FROM SupplierParts sp
    WHERE sp.part_count > 5
),
TotalLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    r.r_name AS region_name,
    c.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    COALESCE(sp.s_name, 'No Supplier') AS supplier_name,
    tl.total_quantity,
    DENSE_RANK() OVER (PARTITION BY r.r_name ORDER BY co.total_spent DESC) AS spending_rank
FROM region r
LEFT JOIN CustomerOrders co ON r.r_regionkey = co.c_custkey
LEFT JOIN TopSuppliers sp ON sp.s_suppkey = co.order_count
LEFT JOIN TotalLineItems tl ON tl.l_orderkey = co.order_count
WHERE co.total_spent IS NOT NULL
  AND (tl.total_quantity > 100 OR tl.total_quantity IS NULL)
ORDER BY r.r_name, spending_rank;
