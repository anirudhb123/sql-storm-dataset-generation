WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_cost,
        ss.total_parts,
        ROW_NUMBER() OVER (ORDER BY ss.total_cost DESC) AS rank
    FROM 
        SupplierSummary ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_cost,
    ts.total_parts,
    t.o_orderkey,
    t.o_orderdate,
    t.o_totalprice
FROM 
    TopSuppliers ts
LEFT JOIN 
    orders t ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#35'))
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.total_cost DESC, t.o_orderdate DESC;
