WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1 WHERE s1.s_nationkey = s.s_nationkey)
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '2022-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_name,
    p.p_brand,
    r.r_name AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS final_price,
    COALESCE(MAX(psd.total_supply_cost), 0) AS max_supply_cost,
    COALESCE(AVG(s.s_acctbal), 0) AS avg_acctbal,
    COUNT(distinct o.o_orderkey) AS order_count
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    OrderStatistics o ON o.o_orderkey = l.l_orderkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000 
ORDER BY 
    final_price DESC, avg_acctbal DESC;
