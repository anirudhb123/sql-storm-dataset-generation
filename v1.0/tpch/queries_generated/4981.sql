WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS total_parts, 
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate, 
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT 
        order_year,
        ROW_NUMBER() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS order_rank,
        total_revenue,
        customer_count
    FROM 
        OrderStats
),
NationSupplier AS (
    SELECT 
        n.n_name AS nation_name, 
        s.s_name AS supplier_name, 
        ss.total_parts, 
        ss.total_available
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    ns.nation_name,
    ns.supplier_name,
    COALESCE(ns.total_parts, 0) AS total_parts,
    COALESCE(ns.total_available, 0) AS total_available,
    ro.total_revenue,
    ro.customer_count
FROM 
    NationSupplier ns
LEFT JOIN 
    RankedOrders ro ON ns.total_available > 0 AND ro.order_year = 2023
WHERE 
    ns.total_parts > 10
ORDER BY 
    ns.nation_name, ro.total_revenue DESC
LIMIT 50;
