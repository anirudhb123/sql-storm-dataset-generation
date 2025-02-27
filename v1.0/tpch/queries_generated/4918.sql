WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.c_name,
        r.total_revenue
    FROM 
        RankedOrders r
    WHERE 
        r.revenue_rank <= 10
),
SupplierStatistics AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.c_name,
    t.total_revenue,
    s.s_name,
    COALESCE(s.total_supplier_cost, 0) AS supplier_cost,
    REGION_INFO.r_name
FROM 
    TopRevenueOrders t
LEFT JOIN 
    SupplierStatistics s ON t.o_orderkey = s.ps_partkey
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = t.c_name)
JOIN 
    region REGION_INFO ON REGION_INFO.r_regionkey = n.n_regionkey
WHERE 
    t.total_revenue > (SELECT AVG(total_revenue) FROM TopRevenueOrders)
ORDER BY 
    t.o_orderdate DESC, t.total_revenue DESC;
