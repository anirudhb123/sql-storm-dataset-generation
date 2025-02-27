WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s_nationkey, 1 as depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.depth < 5
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_available_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 50.00
    GROUP BY p.p_partkey, p.p_name
)
SELECT
    c.c_name AS customer_name,
    sh.s_name AS supplier_name,
    ps.p_name AS part_name,
    ps.total_available_qty,
    ps.avg_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY ps.avg_supply_cost DESC) AS rnk
FROM TopCustomers c
JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
JOIN PartStats ps ON sh.s_suppkey IN (
    SELECT ps_suppkey 
    FROM partsupp 
    WHERE ps_partkey IN (SELECT p_partkey FROM part WHERE p_brand = 'BrandX')
)
WHERE ps.supplier_count > 3
ORDER BY c.c_name, supplier_name, part_name;
