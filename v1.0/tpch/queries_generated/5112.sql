WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderstatus,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank <= 10
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        TopOrders to ON l.l_orderkey = to.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    sr.s_name,
    sr.supplier_revenue,
    nt.n_name AS nation,
    r.r_name AS region
FROM 
    SupplierRevenue sr
JOIN 
    supplier s ON sr.s_suppkey = s.s_suppkey
JOIN 
    nation nt ON s.s_nationkey = nt.n_nationkey
JOIN 
    region r ON nt.n_regionkey = r.r_regionkey
ORDER BY 
    sr.supplier_revenue DESC;
