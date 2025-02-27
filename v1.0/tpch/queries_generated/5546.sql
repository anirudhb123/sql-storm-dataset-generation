WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.nation_name,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation r ON rs.nation_name = r.n_name
    WHERE 
        rs.rank <= 3
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
)
SELECT 
    to.nation_name,
    to.s_name,
    COUNT(ro.o_orderkey) AS total_orders,
    AVG(ro.order_total) AS avg_order_value
FROM 
    TopSuppliers to
LEFT JOIN 
    RecentOrders ro ON to.s_name = ro.c_name
GROUP BY 
    to.nation_name, to.s_name
ORDER BY 
    to.nation_name, total_orders DESC, avg_order_value DESC;
