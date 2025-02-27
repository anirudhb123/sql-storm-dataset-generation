WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),

HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
),

RegionSupplier AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, r.r_name
)

SELECT 
    ps.ps_partkey,
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COALESCE(SUM(l.l_quantity), 0) AS total_ordered_quantity,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    rs.s_name AS best_supplier,
    rs.s_acctbal AS best_supplier_balance,
    r.nation_name,
    r.region_name
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey AND rs.rank = 1
JOIN 
    RegionSupplier r ON r.total_suppliers > 5
GROUP BY 
    ps.ps_partkey, p.p_name, rs.s_name, rs.s_acctbal, r.nation_name, r.region_name
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    total_revenue DESC;
