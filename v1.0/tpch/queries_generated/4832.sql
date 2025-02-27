WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER(PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
SuppliersWithHighValueOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        o.o_orderkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        HighValueOrders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name, o.o_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT h.o_orderkey) AS high_value_order_count,
    SUM(s.s_acctbal) AS total_supplier_acctbal
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers s ON n.n_nationkey = s.s_nationkey AND s.rn <= 3
LEFT JOIN 
    SuppliersWithHighValueOrders h ON s.s_suppkey = h.s_suppkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT h.o_orderkey) > 0
ORDER BY 
    total_supplier_acctbal DESC;
