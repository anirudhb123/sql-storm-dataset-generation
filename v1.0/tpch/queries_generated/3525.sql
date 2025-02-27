WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.order_rank <= 5
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
RevenuePerSupplier AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(SUM(r.total_revenue), 0) AS total_revenue,
    COALESCE(SUM(s.total_supply_cost), 0) AS total_supply_cost,
    COALESCE(SUM(rs.supplier_revenue), 0) AS total_supplier_revenue
FROM 
    nation n
LEFT JOIN 
    TopOrders r ON n.n_nationkey = (SELECT s_nationkey FROM supplier s WHERE s.s_suppkey = r.o_orderkey)
LEFT JOIN 
    SupplierStats s ON n.n_nationkey = (SELECT c_nationkey FROM customer c WHERE c.c_custkey = r.o_orderkey)
LEFT JOIN 
    RevenuePerSupplier rs ON n.n_nationkey = (SELECT c_nationkey FROM customer c WHERE c.c_custkey = rs.s_suppkey)
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC, n.n_name;
