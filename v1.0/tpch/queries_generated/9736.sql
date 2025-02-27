WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_size BETWEEN 10 AND 20
    AND 
        s.s_acctbal > 500.00
),
TopSuppliers AS (
    SELECT 
        s_suppkey, 
        s_name, 
        nation_name, 
        p_name, 
        ps_availqty, 
        ps_supplycost
    FROM 
        RankedSuppliers
    WHERE 
        rnk = 1
)
SELECT 
    ts.s_name,
    SUM(ts.ps_availqty) AS total_available_quantity,
    AVG(ts.ps_supplycost) AS average_supply_cost
FROM 
    TopSuppliers ts
JOIN 
    customer c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = ts.nation_name)
JOIN 
    orders o ON o.o_custkey = c.c_custkey
JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY 
    ts.s_name
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC
LIMIT 10;
