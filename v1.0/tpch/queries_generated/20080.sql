WITH RecursivePartCounts AS (
    SELECT 
        ps.partkey,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        partsupp ps
    GROUP BY 
        ps.partkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1) 
            THEN 'High' 
            ELSE 'Low' 
        END AS acctbal_status
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS row_num
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, l.l_partkey
),
SupplierPartCounts AS (
    SELECT 
        ps.ps_supkey, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_supkey
)
SELECT 
    p.p_name,
    COALESCE(rc.total_availqty, 0) AS available_quantity,
    COALESCE(spc.part_count, 0) AS unique_parts_supplied,
    hvs.acctbal_status,
    SUM(od.revenue) AS total_revenue
FROM 
    part p
LEFT JOIN 
    RecursivePartCounts rc ON p.p_partkey = rc.partkey
LEFT JOIN 
    SupplierPartCounts spc ON spc.ps_supkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey = p.p_partkey 
        ORDER BY 
            ps.ps_supplycost ASC 
        LIMIT 1
    )
LEFT JOIN 
    HighValueSuppliers hvs ON hvs.s_suppkey = (
        SELECT 
            l.l_suppkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_partkey = p.p_partkey 
        ORDER BY 
            l.l_quantity DESC 
        LIMIT 1
    ) 
LEFT JOIN 
    OrderDetails od ON od.l_partkey = p.p_partkey
GROUP BY 
    p.p_name, rc.total_availqty, spc.part_count, hvs.acctbal_status
HAVING 
    (SUM(od.revenue) > 1000 OR hvs.acctbal_status = 'High')
ORDER BY 
    available_quantity DESC, total_revenue DESC;
