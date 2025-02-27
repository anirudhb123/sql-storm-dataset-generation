WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighCostSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name,
        rs.total_cost,
        n.n_name AS nation_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    hcs.s_name, 
    hcs.total_cost, 
    ods.order_revenue,
    (hcs.total_cost / NULLIF(ods.order_revenue, 0)) * 100 AS cost_to_revenue_ratio
FROM 
    HighCostSuppliers hcs
JOIN 
    OrderDetails ods ON hcs.s_suppkey = ods.o_orderkey
ORDER BY 
    cost_to_revenue_ratio DESC;
