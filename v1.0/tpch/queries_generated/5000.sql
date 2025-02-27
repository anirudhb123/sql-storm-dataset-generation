WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal BETWEEN 100.00 AND 1000.00
)
SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity_sold,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    r.r_name AS supplier_region,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Volume'
        WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category
FROM 
    lineitem l
JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    SupplierParts sp ON l.l_partkey = sp.ps_partkey AND sp.rank = 1
LEFT JOIN 
    supplier s ON sp.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= DATEADD(year, -1, GETDATE()) 
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, r.r_name, s.s_name
HAVING 
    AVG(l.l_extendedprice * (1 - l.l_discount)) > 50.00
ORDER BY 
    total_quantity_sold DESC
