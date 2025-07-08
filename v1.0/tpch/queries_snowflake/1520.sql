WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
SupplierPartCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TotalSales AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(supplier_count, 0) AS supplier_count,
    COALESCE(total_sales, 0) AS total_sales,
    RANK() OVER (ORDER BY COALESCE(total_sales, 0) DESC) AS sales_rank,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    SupplierPartCounts spc ON p.p_partkey = spc.ps_partkey
LEFT JOIN 
    TotalSales ts ON p.p_partkey = ts.l_partkey
JOIN 
    nation n ON n.n_nationkey = (SELECT max(s_nationkey) FROM supplier s WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey))
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice BETWEEN 10 AND 500
    AND p.p_type LIKE '%metal%'
    AND (SELECT COUNT(*) FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)) > 0
ORDER BY 
    total_sales DESC, 
    supplier_count DESC;