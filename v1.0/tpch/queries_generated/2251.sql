WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND 
        o.o_orderdate < DATE '2023-01-01'
),
TopNOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        RankedOrders o
    WHERE 
        o.order_rank <= 10
),
SupplierStats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(*) AS num_parts
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
),
NationarySuppliers AS (
    SELECT 
        n.n_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_regionkey,
        ns.total_cost,
        ns.num_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        SupplierStats ns ON s.s_suppkey = ns.ps_suppkey
    WHERE 
        s.s_acctbal > 10000
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(COALESCE(ns.total_cost, 0)) AS total_supplier_cost,
    AVG(ns.num_parts) AS avg_parts_per_supplier
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats ns ON n.n_nationkey = ns.ps_suppkey
JOIN 
    TopNOrders o ON ns.ps_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey))
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    region_name, nation_name;
