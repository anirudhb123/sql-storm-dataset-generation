WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        sc.s_suppkey,
        sc.s_name,
        sc.total_cost
    FROM 
        SupplierCosts sc
    WHERE 
        sc.cost_rank <= 3
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate > '2022-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    t.s_name AS supplier_name,
    t.total_cost AS supplier_total_cost,
    o.total_revenue AS order_revenue,
    o.customer_count AS unique_customers,
    r.r_name AS supplier_region
FROM 
    TopSuppliers t
LEFT JOIN 
    nation n ON t.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    OrderStats o ON o.total_revenue > t.total_cost * 0.5
WHERE 
    COALESCE(o.customer_count, 0) > 0
ORDER BY 
    t.total_cost DESC, o.total_revenue DESC;
