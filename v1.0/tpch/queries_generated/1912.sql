WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
), 
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_supplycost,
        ps.ps_availqty,
        p.p_name
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 100
), 
LineItemsWithDiscount AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderstatus,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(l.total_revenue, 0) AS total_revenue,
    COUNT(s.psi_partkey) AS supplier_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    RankedOrders r
LEFT JOIN 
    LineItemsWithDiscount l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierPartInfo s ON s.ps_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_availqty > 50
    )
WHERE 
    r.rn = 1
GROUP BY 
    r.o_orderkey, r.o_orderstatus, r.o_orderdate, r.o_totalprice
ORDER BY 
    r.o_orderdate DESC;
