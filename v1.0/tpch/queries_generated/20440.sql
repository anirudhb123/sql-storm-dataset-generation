WITH recursive part_supplier_totals AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
macro_supplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        supplier s
    LEFT JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
nation_stats AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        SUM(ps.ps_availqty) AS total_supply,
        AVG(s.s_acctbal) AS avg_supplier_balance,
        MAX(s.s_acctbal) AS max_supplier_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    pt.total_cost,
    COALESCE(ns.total_supply, 0) AS total_supply,
    ns.n_name AS nation_name,
    ms.total_revenue,
    ms.order_count,
    ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY pt.total_cost DESC) AS rank_cost,
    (CASE WHEN ms.order_count IS NULL THEN 'No Orders' ELSE 'Active Orders' END) AS order_status,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_returnflag = 'R' AND l.l_comment LIKE '%damaged%') AS returns_count
FROM 
    part p
LEFT JOIN 
    part_supplier_totals pt ON p.p_partkey = pt.ps_partkey
LEFT JOIN 
    nation_stats ns ON ns.total_supply > 100 AND ns.n_nationkey = (
        SELECT n.n_nationkey
        FROM nation n 
        WHERE n.n_regionkey = (
            SELECT r.r_regionkey 
            FROM region r 
            WHERE r.r_name = 'AFRICA'
        ) AND n.n_comment IS NOT NULL
        ORDER BY n.n_nationkey
        LIMIT 1 OFFSET 1
    )
LEFT JOIN 
    macro_supplier ms ON ms.total_revenue > (
        SELECT AVG(total_revenue) FROM macro_supplier
    )
WHERE 
    (p.p_size BETWEEN 1 AND 20 OR p.p_type LIKE 'MEDIUM%')
AND 
    (p.p_brand = 'Brand#23' OR (p.p_retailprice > 100.00 AND p.p_comment IS NOT NULL))
ORDER BY 
    pt.total_cost DESC, p.p_partkey
LIMIT 50;
