WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), TotalRevenue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    ns.n_name AS nation_name,
    rs.s_name AS supplier_name,
    cs.order_count,
    cs.avg_order_value,
    COALESCE(TR.revenue, 0) AS total_revenue
FROM 
    nation ns
LEFT JOIN 
    RankedSuppliers rs ON ns.n_nationkey = rs.s_nationkey AND rs.rank_within_nation = 1
LEFT JOIN 
    customer cs ON ns.n_nationkey = cs.c_nationkey
LEFT JOIN 
    TotalRevenue TR ON TR.o_orderkey = cs.c_custkey
WHERE 
    cs.order_count > 0 OR TR.revenue IS NOT NULL
ORDER BY 
    total_revenue DESC, supplier_name ASC;
