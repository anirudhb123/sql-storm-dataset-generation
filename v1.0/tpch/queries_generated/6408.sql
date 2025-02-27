WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.total_supply_cost,
        RANK() OVER (ORDER BY s.total_supply_cost DESC) AS cost_rank
    FROM 
        SupplierSummary s
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.total_revenue) AS avg_revenue_per_order,
    COUNT(DISTINCT ts.s_suppkey) AS top_suppliers_count
FROM 
    RankedOrders o
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
JOIN 
    TopSuppliers ts ON ts.cost_rank <= 10
GROUP BY 
    r.r_name
ORDER BY 
    total_orders DESC, avg_revenue_per_order DESC;
