WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers,
        COUNT(l.l_orderkey) AS line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    rs.nation_name,
    COUNT(rs.s_suppkey) AS supplier_count,
    AVG(rs.total_supply_cost) AS avg_supply_cost,
    SUM(os.revenue) AS total_revenue,
    SUM(os.unique_customers) AS total_unique_customers,
    AVG(os.line_items) AS avg_line_items
FROM 
    RankedSuppliers rs
LEFT JOIN 
    OrderStats os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = rs.s_nationkey))
GROUP BY 
    rs.nation_name
ORDER BY 
    total_revenue DESC;
