WITH RankedWeights AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS weight_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) >= 10
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > 10000
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS high_value_order_count,
    AVG(t.total_cost) AS avg_total_cost,
    STRING_AGG(DISTINCT ts.s_name, ', ') AS top_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier ts ON n.n_nationkey = ts.s_nationkey
LEFT JOIN 
    HighValueOrders o ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM RankedWeights p WHERE p.weight_rank <= 5))
GROUP BY 
    r.r_name
ORDER BY 
    high_value_order_count DESC;
