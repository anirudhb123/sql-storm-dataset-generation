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
        rs.*
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.nation_name, 
    SUM(os.revenue) AS total_revenue,
    COUNT(os.o_orderkey) AS order_count
FROM 
    TopSuppliers ts
JOIN 
    partsupp ps ON ts.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    OrderStats os ON l.l_orderkey = os.o_orderkey
GROUP BY 
    ts.nation_name
ORDER BY 
    total_revenue DESC;
