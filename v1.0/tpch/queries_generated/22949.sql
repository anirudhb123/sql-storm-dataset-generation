WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),  
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
), 
FilteredRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    WHERE 
        r.r_name IS NOT NULL AND 
        r.r_name NOT LIKE '%test%'
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    pr.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    COALESCE(FR.r_name, 'Unspecified') AS region_name,
    COUNT(DISTINCT O.o_orderkey) AS total_orders,
    STRING_AGG(s.s_name, ', ') AS supplier_names
FROM 
    part pr
JOIN 
    lineitem l ON pr.p_partkey = l.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey AND rs.rnk = 1
JOIN 
    OrderDetails O ON l.l_orderkey = O.o_orderkey
LEFT JOIN 
    FilteredRegions FR ON fr.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = O.o_custkey))
WHERE 
    pr.p_retailprice BETWEEN 10.00 AND 100.00 AND 
    (l.l_discount IS NULL OR l.l_discount < 0.05)
GROUP BY 
    pr.p_name, FR.r_name
HAVING 
    SUM(l.l_quantity) > 100 
ORDER BY 
    total_quantity DESC;
