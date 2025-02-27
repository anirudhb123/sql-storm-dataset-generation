WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_clerk ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > 1000
), HighValueSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 5000
    GROUP BY 
        ps.ps_suppkey
), OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
), SupplierStats AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        AVG(s.s_acctbal) AS average_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    COALESCE(od.total_price_after_discount, 0) AS total_price_after_discount,
    COALESCE(od.unique_parts, 0) AS unique_parts_count,
    s.n_name AS supplier_nation,
    ss.unique_suppliers,
    ss.average_acctbal
FROM 
    RankedOrders o
LEFT JOIN 
    OrderDetails od ON o.o_orderkey = od.l_orderkey
LEFT JOIN 
    HighValueSuppliers hvs ON EXISTS (
        SELECT 1 
        FROM partsupp ps
        WHERE ps.ps_suppkey = hvs.ps_suppkey
    )
LEFT JOIN 
    SupplierStats ss ON ss.unique_suppliers > 10
JOIN 
    nation s ON hvs.ps_suppkey = s.n_nationkey
WHERE 
    o.rn = 1
ORDER BY 
    o.o_orderdate DESC, 
    o.o_totalprice DESC;
