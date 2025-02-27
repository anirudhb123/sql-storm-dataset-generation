WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.partkey ORDER BY s.s_acctbal DESC) as rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        COUNT(DISTINCT l.l_partkey) AS num_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        COUNT(DISTINCT l.l_partkey) > 5 
        AND SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
NationsWithComment AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(NULLIF(n.n_comment, ''), 'No comment provided') AS comment
    FROM 
        nation n
),
SuppliersWithAverage AS (
    SELECT 
        ps.ps_partkey,
        AVG(s.s_acctbal) OVER (PARTITION BY ps.ps_partkey) AS avg_acctbal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    ns.n_name AS supplier_nation,
    fs.o_orderkey,
    fs.order_total,
    CASE 
        WHEN fs.num_items > 10 THEN 'High volume order'
        ELSE 'Standard order'
    END AS order_type,
    r.s_name AS top_supplier
FROM 
    part p
LEFT JOIN 
    RankedSuppliers r ON r.rnk = 1
LEFT JOIN 
    FilteredOrders fs ON p.p_partkey = fs.o_custkey
JOIN 
    SuppliersWithAverage sa ON p.p_partkey = sa.ps_partkey
JOIN 
    NationsWithComment ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = r.n_name LIMIT 1)
WHERE 
    p.p_size BETWEEN 10 AND 20 
    AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
ORDER BY 
    order_total DESC, p.p_partkey;
