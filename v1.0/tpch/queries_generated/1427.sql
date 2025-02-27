WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
EligibleSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        n.n_name AS nation_name, 
        r.r_regionkey, 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal 
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        RankedSuppliers s ON n.n_nationkey = s.s_nationkey
    WHERE 
        s.rank <= 3
),
TopPart AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_sales DESC 
    LIMIT 5
)
SELECT 
    ep.region_name, 
    ep.nation_name, 
    ep.s_name AS supplier_name, 
    tp.p_name AS top_part_name, 
    tp.total_sales
FROM 
    EligibleSuppliers ep
LEFT JOIN 
    partsupp ps ON ep.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    TopPart tp ON ps.ps_partkey = tp.p_partkey
WHERE 
    ep.s_acctbal IS NOT NULL 
    AND ep.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
ORDER BY 
    ep.region_name, total_sales DESC;
