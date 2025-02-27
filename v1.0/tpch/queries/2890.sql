
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS total_lines
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
TopRegions AS (
    SELECT 
        n.n_nationkey, 
        r.r_name, 
        SUM(o.total_price) AS region_sales
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        OrderSummary o ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT o2.o_custkey FROM orders o2 WHERE o2.o_orderkey = o.o_orderkey))
    WHERE 
        r.r_name IS NOT NULL
    GROUP BY 
        n.n_nationkey, r.r_name
)
SELECT 
    r.r_name, 
    COALESCE(MAX(rs.s_name), 'No Supplier') AS top_supplier,
    COALESCE(SUM(tr.region_sales), 0) AS total_region_sales
FROM 
    TopRegions tr
LEFT JOIN 
    RankedSuppliers rs ON tr.n_nationkey = rs.s_suppkey
FULL OUTER JOIN 
    region r ON tr.n_nationkey = r.r_regionkey
WHERE 
    rs.rnk = 1 OR rs.rnk IS NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_region_sales DESC;
