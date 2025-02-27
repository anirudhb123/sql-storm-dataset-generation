WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartWithMaxSupply AS (
    SELECT ps.ps_partkey, MAX(ps.ps_supplycost) AS max_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_retailprice,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    sh.s_name AS supplier_name,
    co.total_orders,
    co.total_spent,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY co.total_spent DESC) AS order_rank,
    CASE 
        WHEN co.total_orders IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN 
    CustomerOrders co ON s.s_nationkey = co.c_custkey
WHERE 
    p.p_size > 10
    AND p.p_retailprice BETWEEN 100.00 AND 500.00
ORDER BY 
    p.p_partkey,
    nation_name, 
    total_spent DESC;
