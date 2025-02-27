WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    INNER JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 1000
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    nh.n_name AS nation_name,
    ROW_NUMBER() OVER (PARTITION BY nh.n_regionkey ORDER BY total_revenue DESC) AS region_rank,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN CustomerOrders co ON l.l_orderkey = co.o_orderkey
LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN supplier s ON sp.ps_suppkey = s.s_suppkey
LEFT JOIN NationHierarchy nh ON s.s_nationkey = nh.n_nationkey
WHERE p.p_size BETWEEN 5 AND 20
GROUP BY p.p_partkey, p.p_name, nh.n_name
HAVING total_revenue > 1000 OR nh.n_name IS NULL
ORDER BY total_revenue DESC, p.p_partkey ASC;
