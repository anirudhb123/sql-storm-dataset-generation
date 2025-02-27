WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_name AS part_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, p.p_name
), 
OrderTotals AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    rs.nation_name,
    rs.part_name,
    COUNT(DISTINCT ot.o_orderkey) AS order_count,
    AVG(rs.total_cost) AS avg_supplier_cost,
    SUM(ot.total_price) AS total_order_value
FROM 
    RankedSuppliers rs
JOIN 
    OrderTotals ot ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name = rs.part_name)
    )
WHERE 
    ot.total_price > 1000
GROUP BY 
    rs.nation_name, rs.part_name
ORDER BY 
    total_order_value DESC
LIMIT 10;
