WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    rh.s_name AS supplier_name,
    pd.p_name AS part_name,
    co.c_name AS customer_name,
    co.total_orders,
    co.total_spent,
    pd.total_supply_cost,
    RANK() OVER (PARTITION BY co.c_custkey ORDER BY co.total_spent DESC) AS rank_within_customer
FROM SupplierHierarchy rh
LEFT JOIN PartDetails pd ON rh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
JOIN CustomerOrders co ON co.total_spent > 1000
WHERE rh.level <= 5
ORDER BY co.total_spent DESC, pd.total_supply_cost ASC
LIMIT 100;
