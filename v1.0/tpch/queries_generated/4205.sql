WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),

TopSuppliers AS (
    SELECT * 
    FROM SupplierSummary 
    WHERE rn <= 3
)

SELECT 
    p.p_name AS part_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    o.o_orderstatus = 'O' 
    AND l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    revenue DESC;
