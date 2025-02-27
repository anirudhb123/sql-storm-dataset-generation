WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
FilteredSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_supplycost > (SELECT AVG(total_supplycost) FROM SupplierStats)
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    ps.p_name,
    COALESCE(p.total_revenue, 0) AS revenue,
    fs.s_name
FROM 
    RankedOrders ro
LEFT JOIN 
    PartSales p ON p.p_partkey = ro.o_orderkey
LEFT JOIN 
    FilteredSuppliers fs ON fs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
WHERE 
    ro.order_rank = 1
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;
