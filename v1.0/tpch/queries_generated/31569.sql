WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.hierarchy_level < 5
),
TotalCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT c.*, RANK() OVER (ORDER BY total_spent DESC) AS ranking
    FROM CustomerOrders c
)
SELECT 
    p.p_partkey, p.p_name, 
    COALESCE(r.total_supply_cost, 0) AS total_supply_cost,
    s.s_name AS supplier_name,
    CASE 
        WHEN rc.order_count IS NULL THEN 'No Orders'
        WHEN rc.order_count > 5 THEN 'Frequent Customer'
        ELSE 'Occasional Customer' 
    END AS customer_type,
    rh.hierarchy_level AS supplier_hierarchy_level
FROM part p
LEFT JOIN TotalCost r ON p.p_partkey = r.ps_partkey
LEFT JOIN supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
LEFT JOIN RankedCustomers rc ON rc.c_custkey = (SELECT o.o_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_partkey = p.p_partkey LIMIT 1)
LEFT JOIN SupplierHierarchy rh ON s.s_nationkey = rh.s_nationkey
WHERE p.p_retailprice BETWEEN 100 AND 500
ORDER BY total_supply_cost DESC, p.p_partkey;
