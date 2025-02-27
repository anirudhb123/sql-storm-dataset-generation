
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_phone,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_name LIKE '%green%'
),
AggregatedData AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name AS region,
    ad.nation_name,
    ad.total_quantity,
    ad.order_count,
    rs.s_name AS top_supplier,
    rs.s_phone AS supplier_phone,
    rs.s_acctbal AS supplier_acctbal
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    AggregatedData ad ON n.n_name = ad.nation_name
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1 AND n.n_nationkey = (
        SELECT n_nationkey 
        FROM supplier 
        WHERE s_suppkey = rs.s_suppkey
    )
WHERE 
    ad.order_count > 10
ORDER BY 
    ad.total_quantity DESC, ad.order_count DESC;
