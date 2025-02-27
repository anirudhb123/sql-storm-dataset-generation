WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
        r.rank <= 3
)
SELECT 
    p.p_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
GROUP BY 
    p.p_name
ORDER BY 
    revenue DESC
LIMIT 10;
