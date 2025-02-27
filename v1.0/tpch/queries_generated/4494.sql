WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(od.total_price) AS avg_order_value,
    SUM(od.line_count) AS total_lines,
    MAX(od.total_price) AS max_order_value
FROM 
    RankedSuppliers s
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    OrderDetails od ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')))
WHERE 
    s.total_cost > (SELECT AVG(total_cost) FROM RankedSuppliers)
GROUP BY 
    r.r_name, n.n_name, s.s_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    region_name, nation_name, supplier_name;
