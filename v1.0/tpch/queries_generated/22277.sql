WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn <= 3
),
OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS returned_value,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        COUNT(l.l_orderkey) AS total_lines
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.total_cost / NULLIF(o.total_lines, 0) AS avg_cost_per_line,
    o.returned_value,
    CASE 
        WHEN o.returned_value > 1000 THEN 'High Return Value'
        ELSE 'Normal Return'
    END AS return_status,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    TopSuppliers s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    OrderStatistics o ON ps.ps_partkey = o.l_orderkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice IS NOT NULL)
    AND (p.p_retailprice >= 50 OR (p.p_comment LIKE '%Special%' AND p.p_container IS NULL))
ORDER BY 
    avg_cost_per_line DESC
FETCH FIRST 10 ROWS ONLY;
