WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 AS level
    FROM nation n
    WHERE n.n_name = 'Canada'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_regionkey
),
OrderedTotal AS (
    SELECT o.o_orderkey, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierPartDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, s.s_name
)
SELECT 
    p.p_name,
    p.p_brand,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MIN(o.o_orderdate) AS first_order_date,
    MAX(o.o_orderdate) AS last_order_date,
    CASE 
        WHEN MAX(o.o_orderstatus) IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    STRING_AGG(DISTINCT s.s_name, '; ') AS supplier_names,
    nh.level AS nation_level
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN OrderedTotal o ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierPartDetails sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN nation n ON sp.ps_suppkey = n.n_nationkey
LEFT JOIN NationHierarchy nh ON n.n_nationkey = nh.n_nationkey
WHERE p.p_retailprice BETWEEN 10 AND 100
GROUP BY p.p_partkey, p.p_name, p.p_brand, nh.level
HAVING SUM(COALESCE(l.l_quantity, 0)) > 0
ORDER BY revenue DESC
LIMIT 50 OFFSET 0;
