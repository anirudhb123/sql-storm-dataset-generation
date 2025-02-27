
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 10
),
NationSuppliers AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name AS region_name,
    COALESCE(ns.supplier_count, 0) AS total_suppliers,
    COALESCE(rs.total_orders, 0) AS total_orders,
    SUM(COALESCE(sc.total_supply_cost, 0)) AS total_supply_cost
FROM 
    region r
LEFT JOIN 
    NationSuppliers ns ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = r.r_name)
LEFT JOIN 
    (SELECT 
        o.o_orderkey, 
        COUNT(*) AS total_orders 
     FROM 
        RankedOrders o 
     WHERE 
        o.rn = 1 
     GROUP BY 
        o.o_orderkey) rs ON rs.o_orderkey IS NOT NULL
LEFT JOIN 
    SupplierCosts sc ON sc.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = ns.supplier_count))
GROUP BY 
    r.r_name, ns.supplier_count, rs.total_orders
ORDER BY 
    region_name;
