WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, c.c_custkey
)
SELECT 
    r.r_name,
    rs.s_name,
    COUNT(DISTINCT od.o_orderkey) AS order_count,
    SUM(od.total_price) AS total_revenue,
    AVG(rs.total_supply_cost) AS avg_supply_cost
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.rank = 1 AND rs.n_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    OrderDetails od ON rs.s_suppkey = (
        SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (
            SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey LIMIT 1)
        LIMIT 1)
GROUP BY 
    r.r_name, rs.s_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
