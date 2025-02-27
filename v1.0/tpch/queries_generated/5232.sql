WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
    HAVING 
        SUM(o.o_totalprice) > 100000
),
PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name AS customer_name,
    tn.n_name AS nation_name,
    ps.p_name AS part_name,
    ps.supplier_count,
    ps.avg_supplycost,
    ps.total_availqty
FROM 
    RankedOrders ro
JOIN 
    TopNations tn ON ro.c_nationkey = tn.n_nationkey
JOIN 
    PartSupplierStats ps ON ro.o_orderkey = ps.p_partkey
WHERE 
    ro.rank_order <= 10
ORDER BY 
    tn.total_revenue DESC,
    ro.o_totalprice DESC;
