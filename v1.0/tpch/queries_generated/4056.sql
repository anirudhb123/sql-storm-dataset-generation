WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_revenue) FROM (
            SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
            FROM lineitem
            GROUP BY l_orderkey
        ) AS avg_revenue)
),
SupplierStats AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    p.p_name,
    COALESCE(r.s_name, 'No Supplier') AS supplier_name,
    h.total_revenue,
    s.nation_name,
    s.supplier_count,
    s.total_acctbal
FROM 
    part p
LEFT JOIN 
    RankedSuppliers r ON p.p_partkey = r.s_suppkey AND r.supplier_rank = 1
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey LIMIT 1)
LEFT JOIN 
    SupplierStats s ON s.nation_name = (SELECT n.n_name FROM nation n JOIN supplier s2 ON n.n_nationkey = s2.s_nationkey WHERE s2.s_suppkey = r.s_suppkey LIMIT 1)
WHERE 
    p.p_retailprice > 100.00 OR (r.s_suppkey IS NULL AND p.p_size < 50)
ORDER BY 
    p.p_name, h.total_revenue DESC;
