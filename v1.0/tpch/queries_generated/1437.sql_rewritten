WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
), 
SupplierSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        ps.ps_partkey
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT 
    p.p_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(hs.total_supply_cost, 0) AS supplier_cost,
    r.r_name
FROM 
    part p
LEFT JOIN 
    SupplierSales ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN 
    HighValueSuppliers hs ON hs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
JOIN 
    nation n ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 50
    AND (ss.total_sales IS NULL OR ss.total_sales > 5000)
ORDER BY 
    total_sales DESC,
    supplier_cost ASC
LIMIT 10;