WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rnk,
        s.s_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_acctbal IS NOT NULL
        )
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
),
SupplierInfo AS (
    SELECT 
        r.r_name,
        n.n_name,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, n.n_name, s.s_name
)
SELECT 
    s.r_name AS region,
    s.n_name AS nation,
    s.s_name AS supplier,
    rd.total_revenue,
    rd.distinct_parts,
    NULLIF(s.supplier_value / NULLIF(rd.total_revenue, 0), 0) AS supplier_ratio,
    CASE 
        WHEN rd.distinct_parts > 10 THEN 'High' 
        WHEN rd.distinct_parts BETWEEN 5 AND 10 THEN 'Medium' 
        ELSE 'Low' 
    END AS part_availability
FROM 
    SupplierInfo s
LEFT JOIN 
    OrderDetails rd ON s.s_name = (SELECT TOP 1 s1.s_name FROM RankedSuppliers r WHERE r.rnk = 1 AND r.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_availqty > 0) LIMIT 1)
WHERE 
    s.supplier_value > (SELECT AVG(supplier_value) FROM SupplierInfo)
ORDER BY 
    s.r_name, s.n_name DESC, supplier_ratio ASC;
