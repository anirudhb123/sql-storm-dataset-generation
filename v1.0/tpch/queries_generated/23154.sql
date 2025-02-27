WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND p.p_size BETWEEN 1 AND 20
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice IS NOT NULL 
        AND o.o_orderstatus IN ('O', 'F')
),
SupplierSales AS (
    SELECT 
        l.l_suppkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' 
        AND l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        l.l_suppkey
)
SELECT 
    r.s_suppkey, 
    r.s_name, 
    r.s_acctbal,
    COALESCE(h.o_orderkey, 0) AS last_order_key,
    COALESCE(h.o_totalprice, 0) AS last_order_price,
    COALESCE(h.o_orderdate, '1900-01-01') AS last_order_date,
    COALESCE(s.total_sales, 0) AS supplier_sales,
    COUNT(DISTINCT p.p_partkey) AS part_count,
    AVG(p.p_retailprice) AS average_price
FROM 
    RankedSuppliers r
LEFT JOIN 
    HighValueOrders h ON r.s_suppkey = h.o_orderkey
LEFT JOIN 
    SupplierSales s ON r.s_suppkey = s.l_suppkey
JOIN 
    partsupp ps ON r.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    r.rn = 1 
    AND (s.total_sales > (SELECT AVG(total_sales) FROM SupplierSales) 
         OR s.total_sales IS NULL)
GROUP BY 
    r.s_suppkey, 
    r.s_name, 
    r.s_acctbal,
    h.o_orderkey,
    h.o_totalprice,
    h.o_orderdate
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    average_price DESC NULLS LAST;
