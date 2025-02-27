WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        rs.s_name AS supplier_name, 
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs 
    JOIN 
        region r ON rs.s_nationkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1995-01-01' 
        AND l.l_shipdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ts.region_name, 
    ts.supplier_name, 
    SUM(od.revenue) AS total_revenue
FROM 
    TopSuppliers ts
JOIN 
    OrderDetails od ON od.o_orderkey IN (SELECT DISTINCT o.o_orderkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = ts.s_nationkey))
GROUP BY 
    ts.region_name, ts.supplier_name
ORDER BY 
    ts.region_name, total_revenue DESC;
