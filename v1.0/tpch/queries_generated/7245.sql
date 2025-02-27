WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_per_nation
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
        nation_name,
        s.s_suppkey,
        s.s_name,
        total_supply_cost
    FROM 
        RankedSuppliers r
    JOIN 
        supplier s ON r.s_suppkey = s.s_suppkey
    WHERE 
        r.rank_per_nation <= 5
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    l.l_orderkey,
    l.l_partkey,
    l.l_quantity,
    ts.s_name AS top_supplier_name,
    ts.total_supply_cost
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
WHERE 
    o.o_orderstatus = 'F' AND 
    l.l_shipdate >= DATE '2023-01-01' AND 
    l.l_shipdate < DATE '2023-12-31'
ORDER BY 
    ts.total_supply_cost DESC, c.c_name;
