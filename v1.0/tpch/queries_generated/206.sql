WITH RevenueCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY o.o_orderkey
),
SupplierCTE AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_container,
    COALESCE(rev.total_revenue, 0) AS total_revenue,
    COALESCE(sup.unique_suppliers, 0) AS unique_suppliers_count,
    CASE 
        WHEN rev.total_revenue IS NULL THEN 'No Revenue'
        WHEN rev.total_revenue > 500000 THEN 'High Revenue'
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM part p
LEFT JOIN RevenueCTE rev ON p.p_partkey = rev.o_orderkey
LEFT JOIN (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        n.n_name,
        COUNT(ps.ps_partkey) AS unique_parts
    FROM SupplierCTE s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.nation_name = n.n_name
    WHERE s.s_acctbal > 10000
    GROUP BY s.s_suppkey, s.s_name, n.n_name
) sup ON sup.s_suppkey = p.p_partkey
WHERE p.p_retailprice > 0
ORDER BY total_revenue DESC, p.p_name ASC
LIMIT 100;
