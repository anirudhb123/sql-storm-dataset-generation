WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 5
),
RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        SUM(ps.ps_availqty) AS total_available,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    nh.n_name AS nation_name,
    COALESCE(cp.total_orders, 0) AS total_orders_by_customer,
    COALESCE(cp.total_revenue, 0) AS total_revenue_by_customer,
    rp.p_name AS part_name,
    rp.total_available,
    sh.level AS supplier_level
FROM nation nh
LEFT JOIN CustomerOrders cp ON nh.n_nationkey = cp.c_custkey
LEFT JOIN RankedParts rp ON rp.rank <= 3
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = nh.n_nationkey
WHERE nh.n_comment IS NOT NULL
  AND (rp.total_available IS NOT NULL OR cp.total_orders > 10)
ORDER BY nh.n_name, cp.total_revenue DESC, rp.total_available DESC;
