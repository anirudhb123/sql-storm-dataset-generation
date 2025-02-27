WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders r
    WHERE 
        r.revenue_rank <= 10
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.total_revenue,
    sp.supplier_name,
    sp.part_name,
    sp.ps_supplycost
FROM 
    TopOrders t
JOIN 
    SupplierPartDetails sp ON t.total_revenue > sp.ps_supplycost
ORDER BY 
    t.total_revenue DESC, t.o_orderdate ASC;
