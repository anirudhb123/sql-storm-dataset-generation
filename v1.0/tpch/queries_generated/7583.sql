WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 500
)
SELECT 
    r.s_suppkey,
    r.s_name,
    r.s_acctbal,
    h.o_orderkey,
    h.total_value
FROM 
    RankedSuppliers r
JOIN 
    HighValueOrders h ON r.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_size IN (10, 20, 30)
    )
WHERE 
    r.supplier_rank <= 3
ORDER BY 
    h.total_value DESC, r.s_acctbal DESC;
