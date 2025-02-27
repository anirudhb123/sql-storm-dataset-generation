WITH RECURSIVE PriceRanks AS (
    SELECT 
        p_partkey,
        p_name,
        p_retailprice,
        DENSE_RANK() OVER (ORDER BY p_retailprice DESC) AS price_rank
    FROM 
        part
), 
RecentOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
        o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o_orderkey, o_custkey, o_orderdate
), 
NationSuppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    SUM(pr.p_retailprice) AS total_part_value,
    ns.supplier_count,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    AVG(ro.total_revenue) AS avg_revenue,
    CASE 
        WHEN SUM(pr.p_retailprice) IS NULL 
        THEN 'No parts' 
        ELSE 'Has parts' 
    END AS part_status,
    STRING_AGG(DISTINCT CASE 
        WHEN pr.price_rank <= 10 THEN pr.p_name 
        END, ', ') FILTER (WHERE pr.price_rank <= 10) AS top_part_names
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part pr ON ps.ps_partkey = pr.p_partkey
LEFT JOIN 
    RecentOrders ro ON s.s_suppkey = ro.o_custkey
LEFT JOIN 
    NationSuppliers ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    (pr.p_retailprice IS NOT NULL OR s.s_comment IS NOT NULL)
GROUP BY 
    r.r_name, ns.supplier_count
HAVING 
    SUM(pr.p_retailprice) > COALESCE(ns.supplier_count, 0) * 1000
ORDER BY 
    total_part_value DESC;
