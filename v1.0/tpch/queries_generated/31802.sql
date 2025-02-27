WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, CAST(r_name AS VARCHAR(255)) AS hierarchy
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, CONCAT(rh.hierarchy, ' -> ', r.r_name)
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey != 1
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
SupplierPartDetails AS (
    SELECT s.s_suppkey, p.p_partkey, SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 10
    GROUP BY s.s_suppkey, p.p_partkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, co.total_spent
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE co.total_spent > 10000
    ORDER BY co.total_spent DESC
    LIMIT 5
)
SELECT 
    th.hierarchy AS region_hierarchy,
    tc.c_name AS customer_name,
    tc.total_spent AS total_spent
FROM TopCustomers tc
CROSS JOIN RegionHierarchy th
LEFT JOIN (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS count_parts
    FROM SupplierPartDetails psd
    LEFT JOIN supplier s ON psd.s_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey
    HAVING COUNT(DISTINCT psd.p_partkey) > 2
) AS diverse_suppliers ON diverse_suppliers.s_suppkey = tc.c_custkey
WHERE NULLIF(tc.total_spent, 0) IS NOT NULL
ORDER BY total_spent DESC;
